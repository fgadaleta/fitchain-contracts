/* global assert, artifacts, contract, before, describe, it */

const CommitReveal = artifacts.require('CommitReveal.sol')
const utils = require('./utils.js')

const web3 = utils.getWeb3()

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
        before(async () => {
            commitReveal = await CommitReveal.deployed()
            commitmentId = utils.soliditySha3(['string'],['commitmentTest'])
        })
        it('setup new commit-reveal scheme', async () => {
            const setupCommitment = await commitReveal.setup(commitmentId, comitTimeout, revealTimeout, voters, {from: genesisAccount})
            assert.strictEqual(setupCommitment.logs[0].args.commitmentId, commitmentId, 'invalid commitment setup')
        })
    })
})