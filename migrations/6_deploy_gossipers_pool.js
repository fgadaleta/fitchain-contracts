/* global artifacts */
const GossipersPool = artifacts.require('GossipersPool.sol')
const Registry = artifacts.require('FitchainRegistry.sol')

const gossipersPool = async (deployer, network) => {
    await deployer.deploy(GossipersPool, Registry.address, 3, 10, 10)
}
module.exports = gossipersPool