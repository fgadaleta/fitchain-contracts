pragma solidity ^0.4.25;

import './FitchainToken.sol';

/**
@title Fitchain Payment Contract
@author Team: Fitchain Team
*/

contract Payment {

    FitchainToken private token;

    constructor(address _fitchainTokenAddress) public{
        require(_fitchainTokenAddress != address(0), 'invalid contract address');
        token = FitchainToken(_fitchainTokenAddress);
    }
}