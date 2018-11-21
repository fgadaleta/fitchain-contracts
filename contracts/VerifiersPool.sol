pragma solidity 0.4.25;

import './FitchainRegistry.sol';
import './CommitReveal.sol';
import './FitchainHelper.sol';

/**
@title Fitchain Model Verifiers Pool Contract (VPC)
@author Team: Fitchain Team
*/

contract VerifiersPool is FitchainHelper, CommitReveal, FitchainRegistry  {

    struct Challenge{
        uint256 wallTime;
        bytes32 modelId;
        bytes32 proofId;
        bytes32 testingData;
        address owner;
        address[] verifiers;
    }

    struct Proof{
        bool exist;
        bool isVerified;
    }

    struct VPCSetting{
        uint256 minKVerifiers;
        uint256 minStake;
    }

    mapping (address => VPCSetting) VPCsettings;
    mapping (bytes32 => Challenge) challenges;
    mapping(bytes32 => Proof) proofs;


    // modifiers
    modifier onlyValidStake(uint256 amount){
        require(amount >= VPCsettings[address(this)].minStake);
        _;
    }

    modifier onlyExistProof(bytes32 proofId) {
        require(proofs[proofId].exist,'Proof does not exist!');
        _;
    }

    // init VPC settings
    constructor(uint256 _minKVerifiers, uint256 _minStake) public {
        VPCsettings[address(this)] = VPCSetting(_minKVerifiers, _minStake);
    }

    function initChallenge(bytes32 modelId, address owner, bytes32 challengeId, uint256 wallTime,
                          uint256 kVerifiers, bytes32 testingData) public returns(bool){

    }
    function getAvailableVerifiers() private view returns(address[]){
        return super.getAvaliableRegistrants();
    }

    function registerVerifier(uint256 amount, uint256 slots) public onlyValidStake(amount) returns(bool){
        return super.register(msg.sender, slots, keccak256(abi.encodePacked(address(this))), amount);
    }

    function deregisterVerifier(address actor) public returns(bool){
        return super.deregister(actor, keccak256(abi.encodePacked(address(this))));
    }

    function getKVerifiers(bytes32 challengeId, uint256 K) private returns(uint256){
        address [] memory verifiersSet = getAvailableVerifiers();
        for(uint256 i=0; i< K; i++){
            challenges[challengeId].verifiers.push(verifiersSet[i]);
            super.decrementActorSlots(verifiersSet[i]);
        }
        return challenges[challengeId].verifiers.length;
    }

    function isVerifiedProof(bytes32 proofId) public view onlyExistProof(proofId) returns(bool){
        return proofs[proofId].isVerified;
    }
}