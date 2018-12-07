/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('GossipersPool', (accounts) => {
    describe('Test Gossipers Pool in Fitchain', () => {
        let token, i
        let staking
        let registry
        let totalSupply
        let genesisAccount = accounts[0]
        let gossipers = [accounts[1], accounts[2], accounts[3]]
        let slots = 1
        let amount = 100
        let channelId = utils.soliditySha3(['string'], ['MyFitchainGossiperChannel'])
        let failToDergister
        let eot = 'THIS IS FAKE END OF TRAINING!'
        let signature
        let proof

        before(async () => {
            token = await FitchainToken.deployed()
            staking = await FitchainStake.deployed()
            registry = await Registry.deployed()
            gossipersPool = await GossipersPool.deployed()

            // init gossiper wallets
            for (i = 0; i < gossipers.length; i++) {
                await token.transfer(gossipers[i], (slots * amount) + 1, { from: genesisAccount })
            }
            totalSupply = await token.totalSupply()
            genesisBalance = web3.utils.toDecimal(await token.balanceOf(genesisAccount))

            stakeId = utils.soliditySha3(['address'], [registry.address])

            assert.strictEqual(totalSupply.toNumber() - ((gossipers.length * slots * amount) + gossipers.length), genesisBalance, 'Invalid transfer!')

            for (i = 0; i < gossipers.length; i++) {
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(gossipers[i])), 'invalid amount of tokens registrant ' + gossipers.length)
            }
        })

        it('should be able register gossipers in the actors registry', async () => {
            for (i = 0; i < gossipers.length; i++) {
                await token.approve(staking.address, (slots * amount), { from: gossipers[i] })
                await gossipersPool.registerGossiper(amount, slots, { from: gossipers[i] })
                assert.strictEqual(await gossipersPool.isRegisteredGossiper(gossipers[i]), true, 'Gossiper is not registered')
            }
        })

        it('should be able to get available gossipers', async () => {
            const availableGossipers = await gossipersPool.getAvailableGossipers()
            assert.strictEqual(availableGossipers.length , gossipers.length, 'invalid available gossipers number')
        })
        it('should be able to initialize a gossiper channel', async () => {
            // initChannel(bytes32 channelId, uint256 KGossipers, uint256 mOfN, address owner)
            const initChannel = await gossipersPool.initChannel(channelId, gossipers.length, gossipers.length, genesisAccount, { from: genesisAccount })
            proofId = initChannel.logs[0].proofId
            assert.strictEqual(channelId, initChannel.logs[0].args.channelId, 'invalid channel Id')
        })
        it('should fail to deregister', async () => {
            for (i = 0; i < gossipers.length; i++) {
                try{
                    await gossipersPool.deregisterGossiper({ from: gossipers[i] })
                    assert.strictEqual(await gossipersPool.isRegisteredGossiper(gossipers[i]), false, 'Gossiper is still registered')
                }catch(error){
                    failToDergister = true
                    assert.strictEqual(failToDergister, true, 'passed the test case without any error!')
                }
            } 
        })
        it('should gossipers submit proof', async () => {
            //submitProof(bytes32 channelId, string eot, bytes32[] merkleroot, bytes signature, bytes32 result)
            const merkleRoot = [utils.soliditySha3(['string'], ['trx1']), utils.soliditySha3(['string'], ['trx2']), utils.soliditySha3(['string'], ['trx3'])]
            const result = utils.soliditySha3(['string'], ['results'])  
            // channelId, merkleroot, eot, result 
            const hash = utils.createHash(web3, channelId, merkleRoot, eot, result)
            for (i = 0; i < gossipers.length; i++) { 
                signature = await web3.eth.sign(hash, gossipers[i])
                proof = await gossipersPool.submitProof(channelId, eot, merkleRoot, signature, result, {from: gossipers[i]})
                assert.strictEqual(proof.logs[0].args.proof, proofId, 'invalid proof Id')
            }
        })
        it('should be able to validata proof', async () => {
            const validateProof = await gossipersPool.validateProof(channelId, { from: genesisAccount })
            console.log(validateProof.logs[0])
            assert.strictEqual(await gossipersPool.isValidProof(channelId), true, 'proof is not valid')
        })
        // it('should be able to deregister gossipers from the actors registry', async () => {
        //     for (i = 0; i < gossipers.length; i++) {
        //         await gossipersPool.deregisterGossiper({ from: gossipers[i] })
        //         assert.strictEqual(await gossipersPool.isRegisteredGossiper(gossipers[i]), false, 'Gossiper is still registered')
        //     }
        // })
        // it('should get zero registered gossipers', async () => {
        //     const noGossipers = await gossipersPool.getAvailableGossipers()
        //     assert.strictEqual(0, noGossipers.length, 'should get zero!') 
        // })
    })
})
