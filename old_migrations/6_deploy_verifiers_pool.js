/* global artifacts */
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const verifiersPool = async (deployer, network) => {
    await deployer.deploy(VerifiersPool, 3, 1, 40, 40)
}
module.exports = verifiersPool