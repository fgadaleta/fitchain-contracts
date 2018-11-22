/* global artifacts */
const Stake = artifacts.require('FitchainStake.sol')
const stake = async (deployer, network) => {
    await deployer.deploy(Stake)
}
module.exports = stake