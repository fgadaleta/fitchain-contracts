/* global artifacts */
const Registry = artifacts.require('FitchainRegistry.sol')
const Stake = artifacts.require('FitchainStake.sol')

const registry = async (deployer, network) => {
    await deployer.deploy(Registry, Stake.address)
}
module.exports = registry