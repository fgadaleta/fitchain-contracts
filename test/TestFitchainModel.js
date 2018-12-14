/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const Model = artifacts.require('FitchainModel.sol')

const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('FitchainModel', (accounts) => {
    describe('Test Fitchain Model Integration', () => {
        let token, i, registry, verifiersPool, gossipersPool, commitReveal, model
        // contracts configurations
        const minModelStake = 100
        const minKVerifiers = 3
        const minKGossipers = 1
        const maxKGossipers = 3
        const minStake = 10
        const commitTimeout = 20
        const revealTimeout = 20
        const genesisAccount = accounts[0]
        const verifiers = [accounts[4], accounts[5], accounts[6]]
        const gossipers = [accounts[1], accounts[2], accounts[3]]
        const dataScientist = accounts[7]
        const dataOwner = accounts[8]
        let slots = 1
        let amount = 200

        before(async () => {
            token = await FitchainToken.new()
            stake = await FitchainStake.new(token.address)
            registry = await Registry.new(stake.address)
            commitReveal = await CommitReveal.new()
            verifiersPool = await VerifiersPool.new(minKVerifiers, minStake, commitTimeout, revealTimeout, commitReveal.address, registry.address)
            gossipersPool = await GossipersPool.new(registry.address, minKGossipers, maxKGossipers, minStake)
            model = await Model.new(minModelStake, gossipersPool.address, verifiersPool.address, stake.address)
            totalSupply = await token.totalSupply()
            genesisBalance = web3.utils.toDecimal(await token.balanceOf(genesisAccount))
            // transfer tokens to verifiers, gossipers, data owner, data scientist
            for(i=0; i < verifiers.length; i++){
                await token.transfer(verifiers[i], (slots * amount) + 1, { from: genesisAccount })
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(verifiers[i])), 'invalid amount of tokens registrant ' + verifiers[i])

            }
            for(i=0; i < gossipers.length; i++){
                await token.transfer(gossipers[i], (slots * amount) + 1, { from: genesisAccount })
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(gossipers[i])), 'invalid amount of tokens registrant ' + gossipers[i])

            }
            await token.transfer(dataScientist, 2 * amount, { from: genesisAccount })
            assert.strictEqual((2 * amount), web3.utils.toDecimal(await token.balanceOf(dataScientist)), 'invalid amount of tokens registrant ' + dataScientist)
            await token.transfer(dataOwner, 2 * amount, { from: genesisAccount })
            assert.strictEqual((2 * amount), web3.utils.toDecimal(await token.balanceOf(dataOwner)), 'invalid amount of tokens registrant ' + dataOwner)


        })
        it('should register verifiers and gossipers', async() => {
            for (i = 0; i < verifiers.length; i++) {
                await token.approve(stake.address, (slots * amount), { from: verifiers[i] })
                await verifiersPool.registerVerifier(amount, slots, { from: verifiers[i] })
                assert.strictEqual(await verifiersPool.isRegisteredVerifier(verifiers[i]), true, 'Verifier is not registered')
            }
            for (i = 0; i < gossipers.length; i++) {
                await token.approve(stake.address, (slots * amount), { from: gossipers[i] })
                await gossipersPool.registerGossiper(amount, slots, { from: gossipers[i] })
                assert.strictEqual(await gossipersPool.isRegisteredGossiper(gossipers[i]), true, 'Gossiper is not registered')
            }
        })
    })
})
