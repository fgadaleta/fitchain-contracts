pragma solidity ^0.4.25;

import './FitchainStake.sol';
import './GossipersPool.sol';
import './VerifiersPool.sol';

/**
@title Fitchain Model Contract
@author Team: Fitchain Team
*/

contract FitchainModel is FitchainStake {

    // fitchain model
    struct Model {
        bool exist;
        bool isTrained;
        bool isVerified;
        uint256 kGossipers;
        uint256 kVerifiers;
        uint256 format;
        address owner;
        bytes32 location;
        bytes32 paymentId;
        bytes32 gossipersPoolId;
        bytes32[] verifiersPoolIds;
        bytes inputSignature;
        string modelType;
    }

    mapping(bytes32 => Model) models;
    uint256 private minStake;
    GossipersPool private gossipersPool;
    VerifiersPool private verifiersPool;


    //events
    event ModelCreated(bytes32 modelId, address owner, bool state);
    event StakeReleased(bytes32 modelId, address to, uint256 amount);
    event ModelPublished(bytes32 modelId, bytes32 location, uint256 format, string modelType, bytes inputSignature);

    modifier notExist(bytes32 modelId){
        require(!models[modelId].exist, 'Model already exist');
        _;
    }

    modifier onlyExist(bytes32 modelId) {
        require(models[modelId].exist,'Model does not exist!');
        _;
    }

    modifier onlyModelOwner(bytes32 modelId){
        require(models[modelId].owner == msg.sender, 'invalid model owner');
        _;
    }

    modifier onlyValidatedModel(bytes32 modelId){
        require(models[modelId].location != bytes32(0), 'model not exists');
        require(models[modelId].isTrained, 'Model is not trained yet!');
        require(gossipersPool.getChannelOwner(modelId) == address(this), 'invalid channel owner');
        _;
    }

    modifier onlyVerifiedModel(bytes32 modelId){
        require(models[modelId].isVerified, 'Model is not verified yet!');
        _;
    }

    constructor(uint256 _minStake, address _gossiperContractAddress, address _verifierContractAddress) public {
        require(_gossiperContractAddress != address(0) && _verifierContractAddress != address(0), 'invalid gossiper contract address');
        gossipersPool = GossipersPool(_gossiperContractAddress);
        verifiersPool = VerifiersPool(_verifierContractAddress);
        minStake = _minStake;
    }

    function createModel(bytes32 modelId, bytes32 paymentRecieptId, uint256 m, uint256 n) public notExist(modelId) returns(bool) {
        if(super.stake(modelId, msg.sender, minStake)){
            models[modelId] = Model(true, false, false, 0,n, 0, msg.sender, bytes32(0), paymentRecieptId, bytes32(0), new bytes32[](0), new bytes(0), new string(0));
            // start goisspers channel
            gossipersPool.initChannel(modelId, n, m, address(this));
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

    function verifyModel(bytes32 modelId, bytes32 challengId, uint256 kVerifiers, uint256 wallTime, bytes32 testingData) public onlyValidatedModel(modelId) onlyModelOwner(modelId) returns(bool){
        models[modelId].kVerifiers = kVerifiers;
        //init verification pool
        verifiersPool.initChallenge(modelId, challengId, wallTime, kVerifiers, testingData);
    }

    function releaseModelStake(bytes32 modelId) public onlyVerifiedModel(modelId) returns(bool) {
        super.release(modelId, models[modelId].owner, minStake);
        emit StakeReleased(modelId, models[modelId].owner, minStake);
        return true;
    }

    function isModelValidated(bytes32 modelId) public view onlyExist(modelId) returns(bool){
        return models[modelId].isTrained;
    }

    function isModelVerified(bytes32 modelId) public view onlyExist(modelId) returns(bool){
        return models[modelId].isVerified;
    }

    function getModelKVerifiersCount(bytes32 modelId) public view onlyExist(modelId) returns(uint256){
        return models[modelId].kVerifiers;
    }

    function getModelKGossipersCount(bytes32 modelId) public view onlyExist(modelId) returns(uint256){
        return models[modelId].kGossipers;
    }

    function getModelChallengeCount(bytes32 modelId) public view onlyExist(modelId) returns(uint256){
        return models[modelId].verifiersPoolIds.length;
    }

    function setModelTrained(bytes32 modelId) public returns(bool) {
        bytes32 proofId = gossipersPool.getProofIdByChannelId(modelId);
        require(gossipersPool.isValidProof(proofId), 'Proof is not valid');
        gossipersPool.terminateChannel(modelId);
        models[modelId].isTrained = true;
    }

    function setModelVerified(bytes32 modelId) public onlyValidatedModel(modelId) {
        for (uint256 i=0; i < models[modelId].verifiersPoolIds.length; i++){
            (address[] memory losers, int8 state) = verifiersPool.getCommitRevealResults(models[modelId].verifiersPoolIds[i]);
            // need to slash or take actions based on the revealed commits
            if(state == -1){
                models[modelId].isVerified = false;
                // emit event indicating commitment did NOT timedout!
            }
            if(state == 0){
                // slash Data-compute provider
                super.slash(modelId, models[modelId].owner, minStake);
                for(uint256 j=0; j < losers.length; j++){
                    //slash verifiers (losers only)
                    verifiersPool.slashVerifier(models[modelId].verifiersPoolIds[i], losers[j]);
                    //TODO: redistribute slashed amount as a reward
                }
            }
            require(verifiersPool.getChallengeOwner(models[modelId].verifiersPoolIds[i]) == address(this), 'invalid challenge owner');
            require(verifiersPool.isVerifiedProof(models[modelId].verifiersPoolIds[i]), 'invalid proof verification');
        }
        models[modelId].isVerified = true;
    }

}