var vpc = artifacts.require("./vpc.sol")

module.exports = function(deployer) {
  deployer.deploy(vpc);
};
