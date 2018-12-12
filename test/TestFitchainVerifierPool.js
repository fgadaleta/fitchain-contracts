/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')

const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('VerifiersPool', (accounts) => {
    describe('Test Verifiers Pool in Fitchain', () => {
        let token, i
        let staking, verifiersPool, commitReveal, genesisBalance
        let totalSupply
        let genesisAccount = accounts[0]
        let verifiers = [accounts[1], accounts[2], accounts[3]]
        let slots = 1
        let amount = 100
        let modelId = utils.soliditySha3(['string'], ['simple model id'])
        let challengeId = utils.soliditySha3(['string'], ['MyFitchainVerifiersPool'])
        let testingData = utils.soliditySha3(['string'], ['this is testing data IPFS hash'])
        let trainedModelResult = '{MSE: 0.002, accuracy: 0.9}'
        let hash = utils.soliditySha3(['bool', 'string'], [true, trainedModelResult])
        let wallTime = 100
        let revealVote
        let state

        before(async () => {
            token = await FitchainToken.deployed()
            staking = await FitchainStake.deployed()
            verifiersPool = await VerifiersPool.deployed()
            commitReveal = await CommitReveal.deployed()

            // init verifiers wallets
            for (i = 0; i < verifiers.length; i++) {
                await token.transfer(verifiers[i], (slots * amount) + 1, { from: genesisAccount })
            }

            totalSupply = await token.totalSupply()
            genesisBalance = web3.utils.toDecimal(await token.balanceOf(genesisAccount))
            assert.strictEqual(totalSupply.toNumber() - ((verifiers.length * slots * amount) + verifiers.length), genesisBalance, 'Invalid transfer!')
            for (i = 0; i < verifiers.length; i++) {
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(verifiers[i])), 'invalid amount of tokens registrant ' + verifiers.length)
            }
        })
        it('should register verifier in the actor registry', async () => {
            for (i = 0; i < verifiers.length; i++) {
                await token.approve(staking.address, (slots * amount), { from: verifiers[i] })
                await verifiersPool.registerVerifier(amount, slots, { from: verifiers[i] })
                assert.strictEqual(await verifiersPool.isRegisteredVerifier(verifiers[i]), true, 'Verifier is not registered')
            }
        })
        it('should the available verifiers equals: ' + verifiers.length, async () => {
            const avaialableVerifiers = await verifiersPool.getAvailableVerifiers()
            assert.strictEqual(avaialableVerifiers.length, verifiers.length, 'invalid available verifiers number')
        })
        it('should able to initialize the verification challenge', async () => {
            await verifiersPool.initChallenge(modelId, challengeId, wallTime, verifiers.length, testingData, { from: genesisAccount })
            assert.strictEqual(await verifiersPool.doesChallengeExist(challengeId), true, 'Challenge does not exist')
        })
        it('should start commit-reveal scheme', async () => {
            let commitStarted
            for (i = 0; i < verifiers.length; i++) {
                commitStarted = await verifiersPool.startCommitRevealPhase(challengeId, { from: verifiers[i] })
            }
            assert.strictEqual(commitStarted.logs[0].args.challengeId, challengeId, 'unable to start commit-reveal phase')
        })
        it('should verifiers commit their votes?', async () => {
            let committedVote
            for (i = 0; i < verifiers.length; i++) {
                committedVote = await commitReveal.commit(challengeId, hash, { from: verifiers[i] })
                assert.strictEqual(committedVote.logs[0].args.voter, verifiers[i], 'unable to commit vote')
            }
        })
        it('unable to reveal during the commit phase', async () => {
            let unableToReveal = 0
            for (i = 0; i < verifiers.length; i++) {
                // reveal(bytes32 _commitmentId, string _value, bool _vote)
                try {
                    revealVote = await commitReveal.reveal(challengeId, trainedModelResult, true, { from: verifiers[i] })
                } catch (error) {
                    unableToReveal += 1
                }
            }
            assert.strictEqual(unableToReveal, verifiers.length, 'unable to catch the error!')
        })
        it('should able to reveal after commit timeout', async () => {
            await utils.sleep(30000)
            const canReveal = await commitReveal.canReveal(challengeId)
            assert.strictEqual(canReveal, true, 'can not reveal')
            for (i = 0; i < verifiers.length; i++) {
                revealVote = await commitReveal.reveal(challengeId, trainedModelResult, true, { from: verifiers[i] })
                assert.strictEqual(challengeId, revealVote.logs[0].args.commitmentId, 'unable to call reveal vote')
            }
        })
        it('should get successful commmit-reveal result after reveal timeout', async () => {
            // getRevealTimeout - currentTime and then sleep for this period of time.
            await utils.sleep(30000)
            // check the result if commitment timedout
            if (await commitReveal.isCommitmentTimedout(challengeId)) {
                let result = await verifiersPool.getCommitRevealResults(challengeId, { from: genesisAccount })
                assert.strictEqual(web3.utils.toDecimal(result.logs[0].args.state), 1, 'invalid state: ' + state)
            } else {
                console.log('error!')
            }
        })
        it('should get the challenge status verified', async () => {
            assert.strictEqual(true, await verifiersPool.isVerifiedProof(challengeId), 'proof is not verified')
        })
        it('should able to deregister all verifiers', async () => {
            for (i = 0; i < verifiers.length; i++) {
                await verifiersPool.deregisterVerifier(verifiers[i], { from: genesisAccount })
            }
            const freedVerifiers = await verifiersPool.getAvailableVerifiers()
            assert.strictEqual(freedVerifiers.length, 0, 'unable to free verifiers')
        })
    })
})
