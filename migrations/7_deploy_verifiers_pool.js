/* global artifacts */
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')
const minKVerifiers = 3
const minStake = 10
const commitTimeout = 20
const revealTimeout = 20

const verifiersPool = async (deployer, network) => {
    await deployer.deploy(VerifiersPool, minKVerifiers, minStake, commitTimeout, revealTimeout, CommitReveal.address, Registry.address)
}
module.exports = verifiersPool