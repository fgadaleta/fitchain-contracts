/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const utils = require('./utils.js')
// This test file tests only one function, other functions are internal
// such as slash, stake, and release functions, therefore they will be tested in other contracts
const web3 = utils.getWeb3()

contract('FitchainStake', (accounts) => {
    describe('Tests Staking in Fitchain', () => {
        let token
        let staking
        const stakingAccount = accounts[1]
        const tokenOwner = accounts[0]

        before(async () => {
            token = await FitchainToken.deployed()
            staking = await FitchainStake.deployed()
        })

        it('should be able to stake 1000 tokens to the contract', async () => {
            await token.approve(staking.address, 1000, {from: tokenOwner})
            await staking.stake(utils.soliditySha3(['string'],['generateRandomStakeId']), 1000, {from: tokenOwner})
            // check that the balance of the staking contract address has received the same value
            assert.strictEqual(1000, web3.utils.toDecimal(await token.balanceOf(staking.address)), 'unable to stake!')
        })
    })
})