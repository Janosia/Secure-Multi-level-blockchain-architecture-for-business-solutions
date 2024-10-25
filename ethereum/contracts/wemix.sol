// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


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

    mapping(bytes32 => TransactionMessage) MessageSession;  // keep track of messages interchanged
    bytes32[] public Messages; // store messages  

}