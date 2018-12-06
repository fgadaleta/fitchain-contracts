/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('GossipersPool', (accounts)=> {
    describe('Test Gossipers Pool in Fitchain', () => {
        let token, i
        let staking
        let registry 
        let totalSupply
        let genesisAccount = accounts[0]
        let gossipers =  [accounts[1], accounts[2], accounts[3]]
        let slots = 1
        let amount = 100

        before(async () => {
            token = await FitchainToken.deployed()
            staking = await FitchainStake.deployed()
            registry = await Registry.deployed()
            gossipersPool = await GossipersPool.deployed()

            // init gossiper wallets 
            for(i=0; i < gossipers.length; i++){
                await token.transfer(gossipers[i], (slots * amount) + 1, { from: genesisAccount })
            }
            totalSupply = await token.totalSupply()
            genesisBalance = web3.utils.toDecimal(await token.balanceOf(genesisAccount))
            
            stakeId = utils.soliditySha3(['address'], [registry.address])
            
            assert.strictEqual(totalSupply.toNumber() - (( gossipers.length * slots * amount) + gossipers.length), genesisBalance, 'Invalid transfer!')
            
            for(i=0; i< gossipers.length; i++){
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(gossipers[i])), 'invalid amount of tokens registrant '+ gossipers.length)
            }
        })

        it('register actors as a gossipers', async() => {
            for(i=0; i < gossipers.length; i++){
                //TODO: change the address 
                await token.approve(staking.address, (slots * amount), { from: gossipers[i] })
            }
        })
    })
})