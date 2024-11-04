// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


///@title contract for simple mapping of address for intra chains in middle layer

contract ChainAddressMiddleLayer{
    mapping (string => uint64) public ChainsMiddleLayer;

    function addAddress(uint64 chain, string calldata dept) public returns(bool){
        ChainsMiddleLayer[dept] = chain;
        return true;
    }

    function returnAddressBottom(string calldata dept) public view returns(uint64){
        require(ChainsMiddleLayer[dept]!=0, "No such dept exists" );
        return (ChainsMiddleLayer[dept]);
    }
}