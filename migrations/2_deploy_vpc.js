var vpc = artifacts.require("Vpc")

module.exports = function(deployer) {
  deployer.deploy(vpc);
};
