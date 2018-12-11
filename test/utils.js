/* eslint-env mocha */
/* eslint-disable no-console */
/* global */
const Web3 = require('web3')
const abi = require('ethereumjs-abi')

const utils = {
    getWeb3: () => {
        const nodeUrl = `http://localhost:${process.env.PORT ? process.env.PORT : '8545'}`
        return new Web3(new Web3.providers.HttpProvider(nodeUrl))
    },
    soliditySha3: (types, values) => {
        return '0x' + abi.soliditySHA3(types, values).toString('hex')
    },
    sleep: (millis) => {
        return new Promise(resolve => setTimeout(resolve, millis))
    },
    createHash: (web3, channelId, merkleRoot, eot, result) => {
        return web3.utils.soliditySha3(
            { type: 'bytes32', value: channelId },
            { type: 'bytes32[]', value: merkleRoot },
            { type: 'string', value: eot },
            { type: 'bytes32', value: result }
        ).toString('hex')
    }
}
module.exports = utils
