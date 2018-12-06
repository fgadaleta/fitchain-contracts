/* global artifacts */
const GossipersPool = artifacts.require('GossipersPool.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const Stake = artifacts.require('FitchainStake.sol')

const gossipersPool = async (deployer, network) => {
    await deployer.deploy(GossipersPool, Registry.address, Stake.address, 3, 10, 10)
}
module.exports = gossipersPool