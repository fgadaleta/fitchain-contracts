var registry = artifacts.require("./registry.sol")

module.exports = function(deployer) {
  deployer.deploy(registry);
};
