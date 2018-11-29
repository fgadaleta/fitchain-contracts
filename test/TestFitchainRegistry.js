/* global assert, artifacts, contract, before, describe, it */

const FitchainToken = artifacts.require('FitchainToken.sol')
const FitchainStake = artifacts.require('FitchainStake.sol')
const Registry = artifacts.require('FitchainRegistry.sol')
const utils = require('./utils.js')

const web3 = utils.getWeb3()

contract('FitchainRegistry', (accounts) => {
    describe('Test Fitchain Registry Contract', () => {
        let token
        let staking
        let registry
        let genesisBalance
        let totalSupply
        let genesisAccount = accounts[0]
        let slots = 3
        let registrant1Addr = accounts[1]
        let registrant2Addr = accounts[2]
        let amount = 100 // tokens per slot
        let stakeId
        before(async () => {
            token = await FitchainToken.deployed()
            staking = await FitchainStake.deployed()
            registry = await Registry.deployed()

            // registrant 1 & 2 buy tokens from genesis account
            await token.transfer(registrant1Addr, (slots * amount) + 1, { from: genesisAccount })
            await token.transfer(registrant2Addr, (slots * amount) + 1, { from: genesisAccount })
            totalSupply = await token.totalSupply()
            genesisBalance = web3.utils.toDecimal(await token.balanceOf(genesisAccount))
            stakeId = utils.soliditySha3(['address'], [registry.address])
            assert.strictEqual(totalSupply.toNumber() - ((2 * slots * amount) + 2), genesisBalance, 'Invalid transfer!')
            assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(registrant1Addr)), 'invalid amount of tokens registrant 1')
            assert.strictEqual((slots * amount) + 1, web3.utils.toDecimal(await token.balanceOf(registrant2Addr)), 'invalid amount of tokens registrant 2')
        })

        it('register an actor with as stake of 3 slots, 100 token per slot', async () => {
            // registrants approve the stake before registration
            await token.approve(staking.address, (slots * amount), { from: registrant1Addr })
            await token.approve(staking.address, (slots * amount), { from: registrant2Addr })
            // call register
            await registry.register(registrant1Addr, slots, stakeId, amount, { from: genesisAccount })
            await registry.register(registrant2Addr, slots, stakeId, amount, { from: genesisAccount })
            assert.strictEqual(await registry.isActorRegistered(registrant1Addr), true, 'actor is not registered!')
            assert.strictEqual(await registry.isActorRegistered(registrant2Addr), true, 'actor is not registered!')
        })
        it('should be able to get the available registrants', async () => {
            const actors = await registry.getAvaliableRegistrants()
            assert.strictEqual(2, actors.length, 'invalid number of actors')
        })
        it('for each actor check assert the number of free slots', async () => {
            const actor1Slots = await registry.getActorFreeSlots(registrant1Addr)
            const actor2Slots = await registry.getActorFreeSlots(registrant2Addr)
            assert.strictEqual(3, actor1Slots.toNumber(), 'invalid slots number')
            assert.strictEqual(3, actor2Slots.toNumber(), 'invalid slots number')
        })
        it('book 2 slots from each actor', async () => {
            await registry.decrementActorSlots(registrant1Addr, { from: genesisAccount })
            await registry.decrementActorSlots(registrant2Addr, { from: genesisAccount })
            const actor1Slots = await registry.getActorFreeSlots(registrant1Addr)
            const actor2Slots = await registry.getActorFreeSlots(registrant2Addr)
            assert.strictEqual(2, actor1Slots.toNumber(), 'invalid slots number')
            assert.strictEqual(2, actor2Slots.toNumber(), 'invalid slots number')
        })
        it('should not be able to deregister, current slots < max slots', async () => {
            try {
                await registry.deregister(registrant1Addr, stakeId, { from: genesisAccount })
            } catch (error) {
                return error
            }
            try {
                await registry.deregister(registrant2Addr, stakeId, { from: genesisAccount })
            } catch (error) {
                return error
            }
        })
        it('slash the first registrant', async () => {
            await registry.slashActor(stakeId, registrant1Addr, amount, true, { from: genesisAccount })
            const actor1MaxSlots = await registry.getActorMaxSlots(registrant1Addr)
            assert.strictEqual(2, actor1MaxSlots.toNumber(), 'invalid max number of slots')
            const actor1Stake = await staking.getStakebyActor(stakeId, registrant1Addr)
            assert.strictEqual(200, actor1Stake.toNumber(), 'invalid stake amount')
        })
        it('increment and deregister actors', async () => {
            await registry.incrementActorSlots(registrant1Addr, { from: genesisAccount })
            const actor1CurSlots = await registry.getActorFreeSlots(registrant1Addr)
            const actor1MaxSlots = await registry.getActorMaxSlots(registrant1Addr)
            assert.strictEqual(actor1CurSlots.toNumber(), actor1MaxSlots.toNumber(), 'invalid numbers')
            await registry.incrementActorSlots(registrant2Addr, { from: genesisAccount })
            await registry.deregister(registrant1Addr, stakeId, { from: genesisAccount })
            await registry.deregister(registrant2Addr, stakeId, { from: genesisAccount })
            assert.strictEqual(false, await registry.isActorRegistered(registrant1Addr), 'actor already exist')
            assert.strictEqual(false, await registry.isActorRegistered(registrant2Addr), 'actor already exist')
        })
        it('assert the released stake of actors', async () => {
            assert.strictEqual(201, web3.utils.toDecimal(await token.balanceOf(registrant1Addr)), 'invalid available tokens')
            assert.strictEqual(301, web3.utils.toDecimal(await token.balanceOf(registrant2Addr)), 'invalid available tokens')
        })
    })
})
