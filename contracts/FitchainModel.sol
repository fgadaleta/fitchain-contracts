pragma solidity ^0.4.25;

import './FitchainStake.sol';
import './GossipersPool.sol';

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
    GossipersPool private gossiper;


    //events
    event ModelCreated(bytes32 modelId, address owner, bool state);
    event StakeReleased(bytes32 modelId, address to, uint256 amount);
    event ModelPublished(bytes32 modelId, bytes32 location, uint256 format, string modelType, bytes inputSignature);

    modifier notExist(bytes32 modelId){
        require(!models[modelId].exist, 'Model already exist');
        _;
    }

    modifier onlyModelOwner(bytes32 modelId){
        require(models[modelId].owner == msg.sender, 'invalid model owner');
        _;
    }

    modifier onlyValidatedModel(bytes32 modelId){
        require(models[modelId].location != bytes32(0), 'model not exists');
        require(models[modelId].isTrained, 'Model not trained yet!');
        // require(models[modelId].isVerfied, 'Model not verified yet!');
        _;
    }

    constructor(uint256 _minStake, address _gossiperContractAddress) public {
        require(_gossiperContractAddress != address(0), 'invalid gossiper contract address');
        gossiper = GossipersPool(_gossiperContractAddress);
        minStake = _minStake;
    }

    function createModel(bytes32 modelId, bytes32 paymentRecieptId, uint256 m, uint256 n) public notExist(modelId) returns(bool) {
        if(super.stake(modelId, msg.sender, minStake)){
            models[modelId] = Model(true, false, false, 0,
                                    msg.sender, bytes32(0),
                                    paymentRecieptId, bytes32(0),
                                    bytes32(0), new bytes(0),
                                    new string(0));
            // start goisspers channel
            // bytes32 channelId, uint256 KGossipers, uint256 mOfN, address owner
            gossiper.initChannel(modelId, n, m, address(this));
            emit ModelCreated(modelId, msg.sender, true);
            return true;
        }
        emit ModelCreated(modelId, msg.sender, false);
        return false;

    }

    function publishModel(bytes32 modelId, bytes32 _location, uint256 _format, string _modelType, bytes _inputSignature) public onlyModelOwner(modelId) returns(bool) {
        models[modelId].location = _location;
        models[modelId].format = _format;
        models[modelId].modelType = _modelType;
        models[modelId].inputSignature = _inputSignature;
        emit ModelPublished(modelId, _location, _format, _modelType, _inputSignature);
        return true;
    }

    function releaseStake(bytes32 modelId) public onlyValidatedModel(modelId) returns(bool) {
        super.release(modelId, models[modelId].owner, minStake);
        emit StakeReleased(modelId, models[modelId].owner, minStake);
        return true;
    }

    function isModelValidated(bytes32 modelId) public view returns(bool){
        return (models[modelId].isTrained && models[modelId].isVerfied);
    }

    function setModelTrained(bytes32 modelId) public onlyValidatedModel(modelId) returns(bool) {
        bytes32 proofId = gossiper.getProofIdByChannelId(modelId);
        require(gossiper.isValidProof(proofId), 'Proof is not valid');
        // terminate channel
        gossiper.terminateChannel(modelId);
        models[modelId].isTrained = true;
    }
}