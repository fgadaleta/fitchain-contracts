/* global artifacts */
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const Staking = artifacts.require('FitchainStake.sol')
const Model = artifacts.require('FitchainModel.sol')
const minModelStake = 100

const model = async (deployer, network) => {
    await deployer.deploy(Model,  minModelStake, GossipersPool.address, VerifiersPool.address, Staking.address)
}
module.exports = model