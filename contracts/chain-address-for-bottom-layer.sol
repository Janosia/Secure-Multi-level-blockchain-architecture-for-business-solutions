// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


contract ChainAddressBottomLayer{
    mapping (string => uint64) public ChainsBottomLayer;

    function addAddressBottom(uint64 chain, string calldata dept) public returns(bool){
        ChainsBottomLayer[dept] = chain;
        return true;
    }
}