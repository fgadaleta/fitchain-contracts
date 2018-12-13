/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('FitchainToken', (accounts) => {
    describe('Tests Fitchain Token contract', () => {
        let token
        let totalSupply
        let receiver1WalletBalance = 0
        let receiver2WalletBalance = 0
        const sender = accounts[0]
        const receiver1 = accounts[1]
        const receiver2 = accounts[2]

        before(async () => {
            token = await FitchainToken.new()
        })

        it('should get the same total supply', async () => {
            totalSupply = await token.totalSupply()
            assert.strictEqual(totalSupply.toNumber(), 10000000000000, 'invalid supply!')
        })

        it('should be able to transfer 1000 tokens to receiver-1 account', async () => {
            await token.transfer(receiver1, 1000, { from: sender })
            receiver1WalletBalance += 1000
            assert.strictEqual(receiver1WalletBalance, web3.utils.toDecimal(await token.balanceOf(receiver1)), 'unable to transfer')
        })
        it('should be able to transfer 100 tokens from receiver-1 to receiver-2', async () => {
            await token.approve(receiver2, 100, { from: receiver1 })
            receiver2WalletBalance += 100
            await token.transferFrom(receiver1, receiver2, 100, { from: receiver2 })
            assert.strictEqual(receiver2WalletBalance, web3.utils.toDecimal(await token.balanceOf(receiver2)), 'unable to transfer')
            assert.strictEqual(receiver1WalletBalance - 100, web3.utils.toDecimal(await token.balanceOf(receiver1)), 'unable to transfer')
        })
    })
})
