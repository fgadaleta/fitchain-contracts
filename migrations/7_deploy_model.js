/* global artifacts */
const Model = artifacts.require('FitchainModel.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const VerifiersPool = artifacts.require('VerifiersPool.sol')

const model = async (deployer, network) => {
    await deployer.deploy(Model, 1,GossipersPool.address, VerifiersPool.address)
}
module.exports = model