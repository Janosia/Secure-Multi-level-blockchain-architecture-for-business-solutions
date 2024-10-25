// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

///  npm install @chainlink/contracts-ccip@1.5.0-beta.0 - for imports to work

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "cross-not-official/contracts/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "cross-not-official/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";


///@title Classify the transactions from beta layer into different chains (3 for our use case)
/// Validate transactions from beta layer and send information back to beta layer 

contract MiddleLayer {
    
    // EVENTS DEFINED
    event SuccessfullClassification(); // when transactions has been successfully added to respective chain
    event SuccessfullValidation(); // when transaction has been validated successfully
    event TransactionRecieved(); // when transaction is recieved from bottom layer
    event TransactionSent(); // when transaction is sent to bottom layer
    // event AlertToAlphaLayer() ; // when we alert alpha layer about any mishaps
    // ERRORS DEFINED 
    error NoChainExists(); // when trasaction type does not belong to any chain; can either report it to alpha layer 
    error FailureinWithdrawl() ; // when transaction fails to withdraw tokens from sender
    error NothingtoWithdraw(); // when sender has no funds left 
    error MessageIDNotFound(); // when Transaction message is not found

    struct TransactionMessage {
        bytes32 MessageID; // ID used for mapping
        string  TransactionType;  // helps in selecting chain
        address sender;
        address reciever;
    }

    struct Message{
        uint64 Sourcechain;  // address chain 
        string SenderDepartment; // Department Name which initialised transaction
        string RecieverDepartment; // Department Name which will recieve transaction   
    }

    mapping(bytes32 => TransactionMessage) TxSession;  // keep track of messages interchanged
    bytes32[] public TxMessages; // store messages  

}