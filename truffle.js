module.exports = {
	networks: {
        development: {
            host: 'localhost',
            port: 8545,
            network_id: '*',
            gas: 6000000
        },
        coverage: {
            host: 'localhost',
            // has to be '*' because this is usually ganache
            network_id: '*',
            port: 8555,
            gas: 0xfffffffffff,
            gasPrice: 0x01
        }
	},

	compilers: {
        solc: {
            version: '0.4.25'
        }
	},
	solc:{
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};
