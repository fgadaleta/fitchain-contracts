/* global artifacts */
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')

const verifiersPool = async (deployer, network) => {
    await deployer.deploy(VerifiersPool, 3, 10, 10, 10, CommitReveal.address, Registry.address)
}
module.exports = verifiersPool