/* global artifacts */
const Payments = artifacts.require('FitchainPayment.sol')
const Model = artifacts.require('FitchainModel.sol')
const payments = async (deployer, network) => {
    await deployer.deploy(Payments, Model.address, 10)
}
module.exports = payments