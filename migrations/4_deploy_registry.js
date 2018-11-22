/* global artifacts */
const Registry = artifacts.require('FitchainRegistry.sol')
const registry = async (deployer, network) => {
    await deployer.deploy(Registry)
}
module.exports = registry