/* global artifacts */
const GossipersPool = artifacts.require('GossipersPool.sol')
const gossipersPool = async (deployer, network) => {
    await deployer.deploy(GossipersPool, 2, 10, 1)
}
module.exports = gossipersPool