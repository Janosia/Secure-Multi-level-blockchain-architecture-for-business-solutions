const CCIPLocalSimulator = artifacts.require("CCIPLocalSimulator");

module.exports = async function (deployer) {
  // Deploy the CCIPLocalSimulator
  await deployer.deploy(CCIPLocalSimulator);
};
