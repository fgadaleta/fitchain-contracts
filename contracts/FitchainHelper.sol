pragma solidity ^0.4.25;

/**
@title Fitchain Supporting Functions
@author team: Fitchain team
*/

contract FitchainHelper {

    function suffle(uint256 k, uint256 s) public view returns(uint256){
        return (uint256(keccak256(abi.encodePacked(block.number-1)))%k + 1)%s + 1;
    }
}