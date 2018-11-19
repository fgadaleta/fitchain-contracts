pragma solidity ^0.4.25;

import './Registry.sol';
import './Stake.sol';

/**
@title Fitchain Model Contract
@author Team: Fitchain Team
*/

contract FitchainModel is FitchainStake {

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
    uint256 private minStake;

    //events
    event ModelCreated(bytes32 modelId, address owner, bool state);

    modifier notExist(bytes32 modelId){
        require(!models[modelId].exist, 'Model already exist');
        _;
    }

    modifier onlyValidatedModel(bytes32 modelId){
        require(models[modelId].location != bytes32(0), 'model not exists');
        require(models[modelId].isTrained, 'Model not trained yet!');
        // require(models[modelId].isVerfied, 'Model not verified yet!');
        _;
    }

    constructor(uint256 _minStake) public {
        minStake = _minStake;
    }

    function createModel(bytes32 modelId, bytes32 paymentRecieptId) public notExist(modelId) returns(bool) {
        if(super.stake(modelId, msg.sender, minStake)){
            models[modelId] = Model(true, false, false, 0,
                                    msg.sender, bytes32(0),
                                    paymentRecieptId, bytes32(0),
                                    bytes32(0), new bytes(0),
                                    new string(0));
            emit ModelCreated(modelId, msg.sender, true);
            return true;
        }
        emit ModelCreated(modelId, msg.sender, false);
        return false;

    }

    function releaseStake(bytes32 modelId) public onlyValidatedModel(modelId) returns(bool) {
        return super.release(modelId, models[modelId].owner, minStake);
    }
}