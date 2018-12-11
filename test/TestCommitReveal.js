/* global assert, artifacts, contract, before, describe, it */

const CommitReveal = artifacts.require('CommitReveal.sol')
const utils = require('./utils.js')

contract('CommitReveal', (accounts) => {
    describe('Test Fitchain Commit Reveal Scheme', () => {
        let commitReveal
        let genesisAccount = accounts[0]
        let actor1 = accounts[1]
        let actor2 = accounts[2]
        let actor3 = accounts[3]
        let voters = [actor1, actor2, actor3]
        let commitmentId
        let comitTimeout = 25
        let revealTimeout = 25
        let message = '{mse:0.002, identity: 0xe4hg3f2ab}'
        let messageHash
        before(async () => {
            commitReveal = await CommitReveal.deployed()
            commitmentId = utils.soliditySha3(['string'], ['commitmentTest'])
            messageHash = utils.soliditySha3(['bool', 'string'], [true, message])
        })
        it('setup new commit-reveal scheme', async () => {
            const setupCommitment = await commitReveal.setup(commitmentId, comitTimeout, revealTimeout, voters, { from: genesisAccount })
            assert.strictEqual(setupCommitment.logs[0].args.commitmentId, commitmentId, 'invalid commitment setup')
        })
        it('commit correct votes by the 3 actors', async () => {
            await commitReveal.commit(commitmentId, messageHash, { from: actor1 })
            await commitReveal.commit(commitmentId, messageHash, { from: actor2 })
            await commitReveal.commit(commitmentId, messageHash, { from: actor3 })
        })
        it('run replay-attack using same commits', async () => {
            try {
                await commitReveal.commit(commitmentId, messageHash, { from: actor1 })
            } catch (error) {
                return error
            }
        })
        it('unable to reveal after commit timeout', async () => {
            try {
                await commitReveal.reveal(commitmentId, message, true, { from: actor1 })
            } catch (error) {
                return error
            }
        })
        it('reveal after 25 seconds timeout', async () => {
            const commitTime = await commitReveal.getCommitTimeout(commitmentId)
            const revealTime = await commitReveal.getRevealTimeout(commitmentId)
            const timestamp = parseInt(Date.now() / 1000)
            if ((commitTime.toNumber() >= timestamp) && (timestamp < revealTime.toNumber())) {
                await utils.sleep(30000)
                if (await commitReveal.canReveal(commitmentId)) {
                    const revealed1stVote = await commitReveal.reveal(commitmentId, message, true, { from: actor1 })
                    await utils.sleep(2)
                    const revealed2ndVote = await commitReveal.reveal(commitmentId, message, true, { from: actor2 })
                    await utils.sleep(2)
                    const revealed3rdVote = await commitReveal.reveal(commitmentId, message, true, { from: actor3 })
                    assert.strictEqual(commitmentId, revealed1stVote.logs[0].args.commitmentId, 'unable to call reveal vote')
                    assert.strictEqual(commitmentId, revealed2ndVote.logs[0].args.commitmentId, 'unable to call reveal vote')
                    assert.strictEqual(commitmentId, revealed3rdVote.logs[0].args.commitmentId, 'unable to call reveal vote')
                } else {
                    console.log('Error')
                }
            }
        })
        it('calculate results of commitment scheme', async () => {
            // wait for reveal time
            await utils.sleep(25000)
            const revealTime = await commitReveal.getRevealTimeout(commitmentId)
            const timestamp = parseInt(Date.now() / 1000)
            if (timestamp > revealTime.toNumber()) {
                const commitmentResult = await commitReveal.getCommitmentResult(commitmentId, voters, { from: genesisAccount })
                assert.strictEqual(commitmentResult.logs[0].args.state.toNumber(), 1, 'Invalid result state, losers are: ' + commitmentResult.logs[0].args.losers)
            } else {
                console.log('Error!')
            }
        })
    })
})
