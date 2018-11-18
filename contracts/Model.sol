pragma solidity ^0.4.25;

import './Registry.sol';
import './Stake.sol';

/**
@title Fitchain Model Contract
@author Team: Fitchain Team
*/

contract FitchainModel is FitchainRegistry, FitchainStake {

    // fitchain model
    struct Model {
        bool exist;
        bool isTrained;
        bool isVerfied;
        uint256 format;
        address owner;
        bytes32 location;
        bytes32 paymentId;
        bytes32 gossipersPoolId;
        bytes32 verifiersPoolId;
        bytes inputSignature;
        string modelType;
    }

    mapping(bytes32 => Model) models;
}