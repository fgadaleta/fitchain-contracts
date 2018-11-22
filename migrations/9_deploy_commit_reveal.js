/* global artifacts */
const CommitReveal = artifacts.require('CommitReveal.sol')
const commitReveal = async (deployer, network) => {
    await deployer.deploy(CommitReveal)
}
module.exports = commitReveal