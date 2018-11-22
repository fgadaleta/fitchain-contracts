var registry = artifacts.require("Registry")

module.exports = function(deployer) {
  deployer.deploy(registry);
};
