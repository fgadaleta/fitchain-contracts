/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')
const Registry = artifacts.require('FitchainRegistry.sol')

const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('FitchainModel', (accounts) => {
    describe('Test Fitchain Model Integration', () => {
        let token, i , registry, verifiersPool, gossipersPool

        before(async () => {
            
            // contracts configurations
            const minModelStake = 100
            const minKVerifiers = 3
            const minStake = 10
            const commitTimeout = 20
            const revealTimeout = 20

            token = await FitchainToken.new()
            stake = await FitchainStake.new(token.address)
            registry = await Registry.new(stake.address)
            verifiersPool = await VerifiersPool.new(minKVerifiers, minStake, commitTimeout, revealTimeout, commitReveal.address, registry.address)

        })

    })
})