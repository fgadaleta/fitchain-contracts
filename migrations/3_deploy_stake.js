/* global artifacts */
const Stake = artifacts.require('FitchainStake.sol')
const Token = artifacts.require('FitchainToken.sol')

const stake = async (deployer, network) => {
    await deployer.deploy(Stake, Token.address)
}
module.exports = stake