// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

///  npm install @chainlink/contracts-ccip@1.5.0-beta.0 - for imports to work

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

///@title Classify the transactions from beta layer into different chains (3 for our use case)
/// Validate transactions from beta layer and send information back to beta layer 

contract MiddleLayer is CCIPReceiver, OwnerIsCreator {
    
    // EVENTS DEFINED
    event SuccessfullClassification(bytes32, address, string, uint); // when transactions has been successfully added to respective chain
    // event SuccessfullValidation(); // when transaction has been validated successfully
    event TransactionRecieved(); // when transaction is recieved from bottom layer
    event TransactionSent(); // when transaction is sent to bottom layer
    // event AlertToAlphaLayer() ; // when we alert alpha layer about any mishaps

    // ERRORS DEFINED
    // error NoChainExists(); // when trasaction type does not belong to any chain; can either report it to alpha layer
    error FailureinWithdrawl(); // when transaction fails to withdraw tokens from sender
    error NothingtoWithdraw(); // when sender has no funds left
    error MessageIDNotFound(); // when Transaction message is not found
    error SenderNotAllowlisted(); // when senders are not allowed to initiate cross chain transactions
    error SourceChainNotAllowlisted(); // when chains are not allowed to send transactions

    // something similar needs to be sent from bottom layer
    struct TransactionMessage {
        bytes32 MessageID; // ID used for mapping
        string TransactionType; // helps in selecting chain
        address sender;
        address reciever;
        uint64 sourcechain;
        string SenderDepartment; // Department Name which initialised transaction
        string RecieverDepartment; // Department Name which will recieve transaction
    }

    struct Message {
        uint64 Sourcechain; // address of intialising chain
        uint64 DestinationChain; // address of recieving chain
        string SenderDepartment; // Department Name which initialised transaction
        string RecieverDepartment; // Department Name which will recieve transaction
        string TransactionType;
    }

    mapping(bytes32 => TransactionMessage) TxSession; // keep track of messages interchanged
    bytes32[] public TxMessages; // store messages
    mapping(string => uint64) ChainAddress; // ["Tx Type" : chain Address] mapping
    // string [] public TxType; // keeps track of existing tx types
    uint64[] public allowlistedSourceChains;
    address[] public allowlistedSenders;
    address public _router = 0x7798b795Fde864f4Cd1b124a38Ba9619B7F8A442; // taken from CCIP website
     
    // Modifier to override definitions
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
    if (!allowlistedSourceChains[_sourceChainSelector])
        revert SourceChainNotAllowlisted(_sourceChainSelector);
    if (!allowlistedSenders[_sender]) 
        revert SenderNotAllowlisted(_sender);
    _;
}
    function buildmessage(
        TransactionMessage memory message
    ) internal returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "Transaction from department ",
                    message.SenderDepartment,
                    " to ",
                    message.RecieverDepartment,
                    " of type ",
                    message.TransactionType
                )
            )
        );
    }

    // figure out router contract
    constructor(address router) CCIPReceiver(router) {}

    function updateRouter(address routerAddr) external {
        _router = routerAddr;
    }

    ///@notice returns what chain transaction will be recorded in
    ///@param TransactionType is recieved from bottom layer
    function selectchain(
        string memory TransactionType
    ) internal view returns (uint64) {
        require(ChainAddress[TransactionType] > 0, "No chain exists for this transaction type");
        return (ChainAddress[TransactionType]);
    }

    /// @notice classifies the transactions sends message to destination chain
    function classifytx(TransactionMessage memory txm) internal {
        uint64 chain = selectchain(txm.TransactionType); // get destination chain
        address rcv = txm.reciever;
        string memory message = buildmessage(txm);
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(rcv), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000}) //setting gas limit mode is strict by default
            ),
            feeToken: address(0) // Setting feeToken to zero address, indicating native asset will be used for fees
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(_router);

        // Get the fee required to send the message
        uint256 fees = router.getFee(chain, evm2AnyMessage);

        // Send the message through the router and store the returned message ID
        bytes32 messageId = router.ccipSend{value: fees}(chain, evm2AnyMessage);

        emit SuccessfullClassification(messageId, rcv, message, fees);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        ) // Make sure source chain and sender are allowlisted
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text

        // emit MessageReceived(
        //     any2EvmMessage.messageId,
        //     any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
        //     abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
        //     abi.decode(any2EvmMessage.data, (string))
        // );
    }
}