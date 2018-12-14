/* global artifacts */
const Token = artifacts.require('FitchainToken.sol')
const Model = artifacts.require('FitchainModel.sol')
const Payment = artifacts.require('FitchainPayment.sol')
const minWallTime = 300

const payment = async (deployer, network) => {
    await deployer.deploy(Payment, Model.address, minWallTime, Token.address)
}
module.exports = payment