const { assert } = require("chai");
const Web3 = require("web3");

const CCIPLocalSimulator = artifacts.require("CCIPLocalSimulator");
const Sender = artifacts.require("Sender");
const Receiver = artifacts.require("Receiver");
const LinkToken = artifacts.require("LinkToken");
const MockCCIPRouter = artifacts.require("MockCCIPRouter");

contract("CCIP Functionality Test", async (accounts) => {
  let simulator, sender, receiver, linkToken, router;
  const [senderAddress, receiverAddress] = accounts;

  beforeEach(async () => {
    // Retrieve already deployed contracts
    simulator = await CCIPLocalSimulator.deployed();
    sender = await Sender.deployed();
    receiver = await Receiver.deployed();

    // Get the deployed LinkToken and MockCCIPRouter addresses from the simulator
    const configuration = await simulator.configuration();
    linkToken = await LinkToken.at(configuration.linkToken_);
    router = await MockCCIPRouter.at(configuration.sourceRouter_);
  });

  it("should deploy contracts correctly", async () => {
    assert.ok(sender.address, "Sender contract should be deployed");
    assert.ok(receiver.address, "Receiver contract should be deployed");
    assert.ok(simulator.address, "CCIPLocalSimulator contract should be deployed");
  });

  it("should allow the sender to request LINK tokens from the faucet", async () => {
    const amount = Web3.utils.toWei("10", "ether"); // Request 10 LINK tokens
    const receipt = await simulator.requestLinkFromFaucet(senderAddress, amount);

    // Check the balance of LINK tokens in the sender's address
    const senderLinkBalance = await linkToken.balanceOf(senderAddress);
    assert.equal(senderLinkBalance.toString(), amount, "Sender should have received the requested LINK tokens");

    // Ensure the transaction was successful
    assert.equal(receipt.receipt.status, true, "LINK request should be successful");
  });

  it("should simulate a cross-chain transfer", async () => {
    const transferAmount = Web3.utils.toWei("5", "ether");

    // Simulate the transfer from sender to receiver through the router
    await sender.simulateTransfer(receiverAddress, transferAmount);

    // Check the receiver's balance after the transfer
    const receiverBalance = await linkToken.balanceOf(receiverAddress);
    assert.equal(receiverBalance.toString(), transferAmount, "Receiver should have received the correct transfer amount");
  });

  it("should verify the mock router is being used for cross-chain transfer", async () => {
    const initialRouterBalance = await linkToken.balanceOf(router.address);

    // Perform the cross-chain transfer again
    await sender.simulateTransfer(receiverAddress, Web3.utils.toWei("5", "ether"));

    const finalRouterBalance = await linkToken.balanceOf(router.address);

    // Verify that the router has the correct change in balance
    assert.equal(
      finalRouterBalance.toString(),
      (BigInt(initialRouterBalance) + BigInt(Web3.utils.toWei("5", "ether"))).toString(),
      "Router balance should update after a cross-chain transfer"
    );
  });
});
