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
        bool exist;
        uint256 wallTime;
        uint256 canCommit;
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
        uint256 commitTimeout;
        uint256 revealTimeout;
    }

    mapping (address => VPCSetting) VPCsettings;
    mapping (bytes32 => Challenge) challenges;
    mapping(bytes32 => Proof) proofs;
    mapping(bytes32 => mapping (address => uint256)) voteOnce;


    // events
    event ChallengeInitialized(bytes32 challengeId, address[] verifiers, bytes32 proofId, bytes32 testingData);
    event CommitPhaseStarted(bytes32 challengeId, address[] verifiers);

    // modifiers
    modifier onlyChallengeVerifiers(bytes32 challengeId){
        bool isVerifier = false;
        require(challenges[challengeId].exist, 'Challenge does not exist!');
        for(uint256 i=0; i < challenges[challengeId].verifiers.length; i++){
            if(msg.sender == challenges[challengeId].verifiers[i]) isVerifier = true;
        }
        require(isVerifier, 'sender is not a verifier for this challenge');
        _;
    }

    modifier onlyChallengeOwner(bytes32 challengeId){
        require(address(this) == challenges[challengeId].owner, 'invalid challenge owner');
        _;
    }

    modifier onlyValidStake(uint256 amount){
        require(amount >= VPCsettings[address(this)].minStake);
        _;
    }

    modifier onlyExistProof(bytes32 proofId) {
        require(proofs[proofId].exist,'Proof does not exist!');
        _;
    }

    modifier onlyExistChallenge(bytes32 challengeId){
        require(challenges[challengeId].exist, 'challege does not exist!');
        _;
    }

    modifier onlyNotExistChallenge(bytes32 challengeId) {
        require(!challenges[challengeId].exist, 'challege already exist');
        _;
    }

    modifier onlyCanVoteOnce(bytes32 challengeId) {
        require(voteOnce[challengeId][msg.sender] < 1, 'indicating replay attack for voting');
        _;
    }

    // init VPC settings
    constructor(uint256 _minKVerifiers, uint256 _minStake, uint256 _commitTimeout, uint256 _revealTimeout) public {
        VPCsettings[address(this)] = VPCSetting(_minKVerifiers, _minStake, _commitTimeout, _revealTimeout);
    }

    function initChallenge(bytes32 modelId, bytes32 challengeId, uint256 wallTime, uint256 kVerifiers, bytes32 testingData) public onlyNotExistChallenge(challengeId) returns(bool){
        require(wallTime > 20, 'invalid wallTime, should be at least greater than average block interval');
        address[] memory verifiers = getAvailableVerifiers();
        if(verifiers.length >= kVerifiers){
            challenges[challengeId] = Challenge(true, block.timestamp + wallTime, 0,modelId, challengeId, testingData, msg.sender, new address[](0));
            require(kVerifiers == getKVerifiers(challengeId, kVerifiers), 'unable to set verifiers for challenge');
            for (uint256 i=0; i < challenges[challengeId].verifiers.length; i++){
                decrementActorSlots(challenges[challengeId].verifiers[i]);
            }
            // now verifiers can start validation using
            emit ChallengeInitialized(challengeId, challenges[challengeId].verifiers, challengeId, testingData);
            return true;
        }
        return false;

    }

    function endOfProcessingPhase(bytes32 challengeId) public onlyChallengeVerifiers(challengeId) onlyCanVoteOnce(challengeId) {
        voteOnce[challengeId][msg.sender] +=1;
        challenges[challengeId].canCommit +=1;
        if (challenges[challengeId].canCommit == challenges[challengeId].verifiers.length){
            emit CommitPhaseStarted(challengeId, challenges[challengeId].verifiers);
            CommitReveal.setup(challengeId, VPCsettings[address(this)].commitTimeout, VPCsettings[address(this)].revealTimeout, challenges[challengeId].verifiers);
        }
    }

    function endOfCommitRevealPhase(bytes32 challengeId) public returns(address[] losers, int8 state){
        if (CommitReveal.isCommitmentTimedout(challengeId)){
            return CommitReveal.getCommitmentResult(challengeId, challenges[challengeId].verifiers);
        }
        // -1 indicate the challenge still not timed-out.
        return (losers, -1);
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

    function slashVerifier(bytes32 challengeId, address actor) public onlyChallengeOwner(challengeId) returns(bool){
        return super.slashActor(keccak256(abi.encodePacked(address(this))), actor, VPCsettings[address(this)].minStake, true);
    }

    function getKVerifiers(bytes32 challengeId, uint256 K) private returns(uint256){
        address[] memory verifiersSet = getAvailableVerifiers();
        for(uint256 i=0; i< K; i++){
            challenges[challengeId].verifiers.push(verifiersSet[i]);
            super.decrementActorSlots(verifiersSet[i]);
        }
        return challenges[challengeId].verifiers.length;
    }

    function isVerifiedProof(bytes32 proofId) public view onlyExistProof(proofId) returns(bool){
        return proofs[proofId].isVerified;
    }

    function getChallengeOwner(bytes32 challengeId) public view onlyExistChallenge(challengeId) returns(address){
        return challenges[challengeId].owner;
    }

}