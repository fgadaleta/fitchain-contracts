/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      // from: "0x93fcc87df600b308106ce821857445b4c232b22b",
      gas: 5000000,
      network_id: "*" // Match any network id
    }
  }
};
