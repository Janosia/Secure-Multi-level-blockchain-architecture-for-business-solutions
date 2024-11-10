const LinkToken = artifacts.require("LinkToken");
const MockCCIPRouter = artifacts.require("MockCCIPRouter");
const Sender = artifacts.require("Sender");
const Receiver = artifacts.require("Receiver");

module.exports = async function (deployer) {
  // Deploy LinkToken and MockCCIPRouter contracts
  await deployer.deploy(LinkToken);
  const linkToken = await LinkToken.deployed();

  await deployer.deploy(MockCCIPRouter);
  const mockRouter = await MockCCIPRouter.deployed();

  // Deploy Sender contract with LinkToken and MockCCIPRouter addresses
  await deployer.deploy(Sender, linkToken.address, mockRouter.address);
  const sender = await Sender.deployed();

  // Deploy Receiver contract with only the MockCCIPRouter address
  await deployer.deploy(Receiver, mockRouter.address);
  const receiver = await Receiver.deployed();
};
