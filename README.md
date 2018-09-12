# Fitchain contracts

Implementation of the fitchain registry and Validator Pool Contract (VPC) for the Ethereum blockchain.
The two contracts hereby implemented are 

- `vpc.sol`: registry of actors (data owner, data scientist, validator) and validation channels
- `registry.sol`:  registry of models and model challenges

## Getting Started

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


## Authors

* **Francesco Gadaleta** - *Initial work* - [fgadaleta](https://github.com/fgadaleta)

See also the list of [contributors](CONTRIBUTORS.md) who participated in this project.

## License

This project is licensed under the GPL License - see the [LICENSE.md](LICENSE.md) file for details
