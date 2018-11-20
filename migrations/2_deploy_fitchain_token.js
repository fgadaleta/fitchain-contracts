/* global artifacts */
const FitchainToken = artifacts.require('FitchainToken.sol')
const fitchainToken = async (deployer, network) => {
    await deployer.deploy(FitchainToken)
}
module.exports = fitchainToken