/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const VerifiersPool = artifacts.require('VerifiersPool.sol')
const GossipersPool = artifacts.require('GossipersPool.sol')
const CommitReveal = artifacts.require('CommitReveal.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const Model = artifacts.require('FitchainModel.sol')
const Payment = artifacts.require('FitchainPayment.sol')

const utils = require('./utils.js')
const web3 = utils.getWeb3()

contract('FitchainModel', (accounts) => {
    describe('Test Fitchain Model Integration', () => {
        let token, i, registry, verifiersPool, gossipersPool, commitReveal, model, stake, payment, revealVote, signature
        // contracts configurations
        const minModelStake = 100
        const minKVerifiers = 3
        const minKGossipers = 1
        const maxKGossipers = 3
        const minStake = 10
        const commitTimeout = 20
        const revealTimeout = 20
        const price = 100
        const genesisAccount = accounts[0]
        const verifiers = [accounts[4], accounts[5], accounts[6]]
        const gossipers = [accounts[1], accounts[2], accounts[3]]
        const dataScientist = accounts[7]
        const dataOwner = accounts[8]
        // model configurations
        let slots = 1
        let amount = 200
        let modelId = utils.soliditySha3(['string'], ['randomModelId'])
        let dataAssetId = utils.soliditySha3(['string'], ['asset'])
        let wallTime = 3600
        let minWallTime = 300
        let createdModel
        let eot = 'THIS IS FAKE END OF TRAINING!'
        let proof
        let modelLocation = 'QmWVZ87MXAwt5wvgsM9akHUnGE5K3SRSKMmkQtPXRsrPUk' // ipfs hash
        let modelFormat = 0 // csv file
        let modelType = 'collection'
        let modelInputSignature = 'hgGDH7843hjds'
        let testingDataId = utils.soliditySha3(['string'], ['testing data for verification game'])
        // model verification challenge
        let trainedModelResult = '{MSE: 0.002, accuracy: 0.9}'
        let trainedModelhash = utils.soliditySha3(['bool', 'string'], [true, trainedModelResult])

        before(async () => {
            token = await FitchainToken.new()
            // payment = await Payment.new(token.address)
            stake = await FitchainStake.new(token.address)
            registry = await Registry.new(stake.address)
            commitReveal = await CommitReveal.new()
            verifiersPool = await VerifiersPool.new(minKVerifiers, minStake, commitTimeout, revealTimeout, commitReveal.address, registry.address)
            gossipersPool = await GossipersPool.new(registry.address, minKGossipers, maxKGossipers, minStake)
            model = await Model.new(minModelStake, gossipersPool.address, verifiersPool.address, stake.address)
            payment = await Payment.new(model.address, minWallTime, token.address)
            // transfer tokens to verifiers, gossipers, data owner, data scientist
            for (i = 0; i < verifiers.length; i++) {
                await token.transfer(verifiers[i], (slots * amount) + 1, { from: genesisAccount })
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(verifiers[i])), 'invalid amount of tokens registrant ' + verifiers[i])
            }
            for (i = 0; i < gossipers.length; i++) {
                await token.transfer(gossipers[i], (slots * amount) + 1, { from: genesisAccount })
                assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(gossipers[i])), 'invalid amount of tokens registrant ' + gossipers[i])
            }
            await token.transfer(dataScientist, 2 * amount, { from: genesisAccount })
            assert.strictEqual((2 * amount), web3.utils.toDecimal(await token.balanceOf(dataScientist)), 'invalid amount of tokens registrant ' + dataScientist)
            await token.transfer(dataOwner, 2 * amount, { from: genesisAccount })
            assert.strictEqual((2 * amount), web3.utils.toDecimal(await token.balanceOf(dataOwner)), 'invalid amount of tokens registrant ' + dataOwner)
        })
        it('should register verifiers and gossipers', async () => {
            for (i = 0; i < verifiers.length; i++) {
                await token.approve(stake.address, (slots * amount), { from: verifiers[i] })
                await verifiersPool.registerVerifier(amount, slots, { from: verifiers[i] })
                assert.strictEqual(await verifiersPool.isRegisteredVerifier(verifiers[i]), true, 'Verifier is not registered')
            }
            for (i = 0; i < gossipers.length; i++) {
                await token.approve(stake.address, (slots * amount), { from: gossipers[i] })
                await gossipersPool.registerGossiper(amount, slots, { from: gossipers[i] })
                assert.strictEqual(await gossipersPool.isRegisteredGossiper(gossipers[i]), true, 'Gossiper is not registered')
            }
        })
        it('should data scientist make payment and send the payment receipt to provider', async () => {
            await token.approve(payment.address, price, { from: dataScientist })
            const lockPayment = await payment.lockPayment(modelId, price, dataOwner, dataAssetId, wallTime, { from: dataScientist })
            assert.strictEqual(lockPayment.logs[0].args.Id, modelId, 'unable to lock payment')
            assert.strictEqual((2 * amount) - price, web3.utils.toDecimal(await token.balanceOf(dataScientist)), 'invalid transfer')
        })
        it('should data owner call creat model and stake on it', async () => {
            await token.approve(stake.address, minModelStake, { from: dataOwner })
            createdModel = await model.createModel(modelId, modelId, minKVerifiers, minKVerifiers, { from: dataOwner })
            assert.strictEqual(((2 * amount) - minModelStake), web3.utils.toDecimal(await token.balanceOf(dataOwner)))
            assert.strictEqual(createdModel.logs[0].args.modelId, modelId, 'unable to init model')
        })
        it('should elected gossipers listen and commit their votes', async () => {
            // submit proof of training
            const merkleRoot = [utils.soliditySha3(['string'], ['trx1']), utils.soliditySha3(['string'], ['trx2']), utils.soliditySha3(['string'], ['trx3'])]
            const result = utils.soliditySha3(['string'], ['results'])
            // modelId, merkleroot, eot, result
            const hash = utils.createHash(web3, modelId, merkleRoot, eot, result)
            for (i = 0; i < gossipers.length; i++) {
                signature = await web3.eth.sign(hash, gossipers[i])
                proof = await gossipersPool.submitProof(modelId, eot, merkleRoot, signature, result, { from: gossipers[i] })
                assert.strictEqual(proof.logs[0].args.proofId, await gossipersPool.getProofIdByChannelId(modelId), 'invalid proof Id')
            }
        })
        it('should set model trained true if reach the total number of gossiper votes', async () => {
            await gossipersPool.validateProof(modelId, { from: dataOwner })
            assert.strictEqual(await gossipersPool.isValidProof(modelId), true, 'invalid proof')
            await model.setModelTrained(modelId, { from: dataOwner })
            assert.strictEqual(await model.isModelTrained(modelId), true, 'Model is not trained')
        })
        it('should data owner publish the trained model', async () => {
            const publishedModel = await model.publishModel(modelId, modelLocation, modelFormat, modelType, modelInputSignature, { from: dataOwner })
            assert.strictEqual(modelId, publishedModel.logs[0].args.modelId, 'unable to publish model')
        })
        it('should start model verification challenge', async () => {
            const verificationChallenge = await model.verifyModel(modelId, verifiers.length, wallTime, testingDataId, { from: dataOwner })
            assert.strictEqual(verificationChallenge.logs[0].args.state, true, 'unable to trigger the verification game')
        })
        it('should start commit-reveal scheme', async () => {
            let commitStarted
            for (i = 0; i < verifiers.length; i++) {
                commitStarted = await verifiersPool.startCommitRevealPhase(modelId, { from: verifiers[i] })
            }
            assert.strictEqual(commitStarted.logs[0].args.challengeId, modelId, 'unable to start commit-reveal phase')
        })
        it('should verifiers commit the same vote', async () => {
            let committedVote
            for (i = 0; i < verifiers.length; i++) {
                committedVote = await commitReveal.commit(modelId, trainedModelhash, { from: verifiers[i] })
                assert.strictEqual(committedVote.logs[0].args.voter, verifiers[i], 'unable to commit vote')
            }
        })
        it('should verifiers reveal pre-image after commit timeout', async () => {
            await utils.sleep(30000)
            const canReveal = await commitReveal.canReveal(modelId)
            assert.strictEqual(canReveal, true, 'can not reveal')
            for (i = 0; i < verifiers.length; i++) {
                revealVote = await commitReveal.reveal(modelId, trainedModelResult, true, { from: verifiers[i] })
                assert.strictEqual(modelId, revealVote.logs[0].args.commitmentId, 'unable to call reveal vote')
            }
        })
        it('should data owner able to set model verified if all verifiers commit their votes', async () => {
            await model.setModelVerified(modelId, { from: dataOwner })
            assert.strictEqual(true, await model.isModelVerified(modelId), 'model is not verified')
        })
        it('should data owner able to release model stake', async () => {
            const releasedModelStake = await model.releaseModelStake(modelId, { from: dataOwner })
            assert.strictEqual(releasedModelStake.logs[0].args.modelId, modelId, 'unable to release stake')
        })
        it('should data owner receive the locked payment', async () => {
            const releasedPayment = await payment.releasePayment(modelId, { from: dataOwner })
            assert.strictEqual(releasedPayment.logs[0].args.Id, modelId, 'unable to release payment')
        })
    })
})
