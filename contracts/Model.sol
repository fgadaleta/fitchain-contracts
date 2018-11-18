pragma solidity ^0.4.25;

import './Registry.sol';
import './Stake.sol';

/**
@title Fitchain Model Contract
@author Team: Fitchain Team
*/

contract FitchainModel is Registry, FitchainStake {

    // fitchain model
    struct Model {
        bool exists;
        bool isVerified;
        bool isActive;
        uint256 currentError;
		uint256 targetError;
        uint256 format;
		uint256 reward;
		address owner;
        bytes32 ipfs;
        address[] verifiers;
        bytes modelSignature;
    }

    mapping(bytes32 => Model) models;

    // events
    event ModelCreated(bytes32 modelId, bytes32 ipfs, address owner, uint256 currentError, uint256 targetError, uint256 format, uint reward, bytes modelSignature);

    // modifiers
    modifier onlyModelOwner(bytes32 modelId) {
        require(models[modelId].owner == msg.sender, 'Invalid model owner');
        _;
    }

    modifier onlyValidErrorRange(uint256 targetError, uint256 currentError) {
        require(targetError!=0 && targetError > 1, 'invalid target error!');
        require(currentError!=0 && currentError > 1, 'invalid current error!');
        _;
    }

    modifier notExist(bytes32 modelId){
        require(!models[modelId].exists, 'model already exists');
        _;
    }
    modifier onlyValidReward(uint256 reward){
        require(reward > 0, 'invalid rward');
        _;
    }

    modifier onlyDeactivatedModel(bytes32 modelId){
        require(!models[modelId].isActive, 'Model is active, verifiers still use this model!');
        _;
    }

    modifier onlyVerifierType(address[] verifiers){
        //TODO: check registrants contract that these verifiers are available and within verifier pool
        _;
    }

    modifier canDeactivate() {
        _;
    }

    function createModel(bytes32 modelId, bytes32 ipfs, uint256 format, uint8 reward, uint256 targetError, uint256 currentError, bytes modelSignature)
    public onlyValidErrorRange(targetError, currentError) notExist(modelId) onlyValidReward(reward) returns(bool){
        models[modelId] = Model(true, false, false, currentError, targetError, format, reward,msg.sender, ipfs, new address[] (0), modelSignature);
        emit ModelCreated(modelId, ipfs, msg.sender, currentError, targetError, format, reward, modelSignature);
        return true;
    }

    function getModel(bytes32 modelId) public view returns(address, bytes32, uint256, uint256, uint256, uint256, bool){
        return (models[modelId].owner,
                models[modelId].ipfs,
                models[modelId].format,
                models[modelId].reward,
                models[modelId].currentError,
                models[modelId].targetError,
                models[modelId].isVerified);
    }

    function revokeModel(bytes32 modelId) public onlyModelOwner(modelId) onlyDeactivatedModel(modelId) returns(bool){
        models[modelId].exists = false;
    }

    function addModelVerifiers(bytes32 modelId, address[] verifiers) public onlyVerifierType(verifiers) returns(bool) {
        models[modelId].verifiers = verifiers;
    }

    function deactivateModel(bytes32 modelId, address verifier) public canDeactivate() returns (bool) {
        models[modelId].isActive = false;
    }
}