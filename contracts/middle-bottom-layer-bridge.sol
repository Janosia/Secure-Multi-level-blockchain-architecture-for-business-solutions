// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

///  npm install @chainlink/contracts-ccip@1.5.0-beta.0 - for imports to work
/// address private _router = 0x7798b795Fde864f4Cd1b124a38Ba9619B7F8A442; // taken from CCIP website
/// Look for link address from website

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";


///@title allow message transmission between middle and bottom layer 

contract MiddleLayer is CCIPReceiver, OwnerIsCreator{
    
    // EVENTS 
    event TransactionRecieved(bytes32, string); // transaction request is recieved from bottom layer
    event TransactionSent(string, uint64); // approved transaction is sent to bottom layer

    // ERRORS 
    error FailureinWithdrawl(); // transaction fails to withdraw tokens from sender
    error NothingtoWithdraw(); // sender has no funds left
    error MessageIDNotFound(); // Transaction message ID is not found
    error NotEnoughBalance(uint256, uint256);
    

    bytes32 private inter_layer_last_message; 
    
    IERC20 private s_linkToken;

    
    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    constructor( address _router, address _link) CCIPReceiver(_router) {
        s_linkToken = IERC20(_link);
    }

    function sendMessagePayLINK(address _receiver,string calldata _text, uint64 _bottomLayerChain)
        external
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _text,
            address(s_linkToken)
        );

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_bottomLayerChain, evm2AnyMessage);

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(router), fees);

        // Send another message to bottom layer (inter-layer bridging) and use it 
        inter_layer_last_message = router.ccipSend(_bottomLayerChain, evm2AnyMessage);
        // Emit an event with message details
        emit TransactionSent("Transaction sent to Bottom Layer to dept and id", _bottomLayerChain);

        // Return the CCIP message ID
        return messageId;
    }

    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: abi.encode(_text), // ABI-encoded string
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array as no tokens are transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit
                    Client.EVMExtraArgsV2({
                        gasLimit: 200_000, // Gas limit for the callback on the destination chain
                        allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                    })
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)internal override{
        bytes32 s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        string memory s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text
        emit TransactionRecieved(s_lastReceivedMessageId,s_lastReceivedText);
    }

}