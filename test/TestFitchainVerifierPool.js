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
        let failToDeregister

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
        it('should able to initialize the verification challenge', async() => {
            // initChallenge(bytes32 modelId, bytes32 challengeId, uint256 wallTime, uint256 kVerifiers, bytes32 testingData)
            await verifiersPool.initChallenge(modelId, challengeId, 100, 3, testingData, { from: genesisAccount })
            assert.strictEqual(await verifiersPool.doesChallengeExist(challengeId), true, 'Challenge does not exist')
        })
    })
})
