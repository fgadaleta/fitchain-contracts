/* eslint-env mocha */
/* eslint-disable no-console */
/* global assert */
const Web3 = require('web3')

const utils = {
    getWeb3: () => {
        const nodeUrl = `http://localhost:${process.env.PORT ? process.env.PORT : '8545'}`
        return new Web3(new Web3.providers.HttpProvider(nodeUrl))
    },
}
module.exports = utils