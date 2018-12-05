[![banner](docs/imgs/fitchain-banner.png)](https://fitchain.io)
# Fitchain contracts

![Fitchain Travis](https://travis-ci.com/aabdulwahed/fitchain-contracts.svg?branch=master)

Fitchain [contracts](docs/ContractsStructure.md) implement the following modules:
- Gossipers pool for proof of training
- Verifiers pool for verification game 
- Commit-Reveal scheme for secure voting
- Actors registry such as verifiers, gossipers, data owners
- Model Registry that manages the model life cycle

## Getting Started

For local deployment, follow the below steps in order to setup fitchain contracts in your machine

1. Start testrpc (or ganache-cli)

``` $ ganache-cli ```


2. Set sender address in ```truffle.js``` with one account created in ```ganache```


```javascript
module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      from: "ganache sender address",  
      gas: 5000000,
      network_id: "*" // Match any network id
    }
  }
};
```

3. Launch truffle

` $ truffle test `


### Installing

Once connected to the Ethereum blockchain (and edited `truffle.js` accordingly), migrate the contracts with 

```$ truffle migrate ```


## Documentation

- [Architecture documentation](docs/ContractsStructure.md)
- [APIs documentation - WIP](docs/api.md)

## Contributing

For any new issue, feature, or update, create a pull request and we will add it there.See also the list 
of [contributors](CONTRIBUTORS.md) who participated in this project. 

## License

This project is licensed under the GPL License - see the [LICENSE.md](LICENSE.md) file for details
