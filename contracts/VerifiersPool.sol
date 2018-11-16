pragma solidity ^0.4.25;

import '/openzeppelin-solidity/contracts/cryptography/ECDSA.sol';
import '/openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract VerifiersPool is Ownable {

    // Fitchain PoT verifier
    struct Verifier {
        bool state; // 0 avaialble
        bool registered;
        bytes32 currChannelId;
        uint256 stake;
    }

    // lighting channels
    struct Channel {
        bool state;
        address owner;
        bytes32 proof;
        address[] verifiers;
    }

    // proof of training
    struct Proof {
        bool verified;
        uint256 MofNSigs; // M of (N=channel[channelId].verifers.length) verified signatures for the same proof
        bytes32 channelId;
        bytes32[] results;
        bytes32[] proofHashs;
        bytes[] signatures;
    }

    // contract settings (only VPC contract owner)
    struct VPCsettings {
        uint256  minKVerifiers;
        uint256  maxKVerifiers;
        uint256  minStake;
    }

    mapping(address => Verifier) verifiers;
    mapping(bytes32 => Channel) channels;
    mapping(bytes32 => Proof) proofs;
    mapping(address => VPCsettings) settings;
    address[] private verifiersSet;

    // events
    event VerifierRegistered(address verifier);
    event VerifierDeregistered(address verifeir);
    event ChannelInitialized(bytes32 channelId, address[] verifiers, bytes32 proofId);
    event ProofOfTraining(bytes32 channelId, bytes32 proofId, address verifier, bytes32 proofHash);
    event PoTValidated(bytes32 channelId, bytes32 proofId);


    // access control modifiers
    modifier requireKVerifiers(uint256 KVerifiers, uint256 mOfN) {
        require(settings[address(this)].minKVerifiers <= KVerifiers, 'indicating small number of verifiers');
        require(settings[address(this)].maxKVerifiers >= KVerifiers, 'indicating large number of verifiers');
        require(getAvailableVerifiers() == KVerifiers, 'K verifiers are not available');
        require(KVerifiers >= mOfN, 'Invalid channel initialization input parameters');
        _;
    }

    modifier isValidChannelId(bytes32 channelId) {
        require(!channels[channelId].state, 'Channel already exists');
        _;
    }

    modifier canRegisterVerifier() {
        require(!verifiers[msg.sender].registered, 'Verifier already registered');
        _;
    }

    modifier canDeregisterVerifier() {
        require(verifiers[msg.sender].currChannelId == bytes32(0), 'Verifier curretly part of channel');
        require(!verifiers[msg.sender].state, 'Can not deregister verifier is busy');
        _;
    }

    modifier isValidStake(){
        require(msg.value >= settings[address(this)].minStake);
        _;
    }

    modifier canVerify(bytes32 channelId) {
        require(verifiers[msg.sender].currChannelId == channelId, 'invalid channelId!');
        _;
    }

    modifier isPotValidated(bytes32 channelId) {
        require(proofs[channels[channelId].proof].verified, 'Unable to terminate channel, PoT not validated yet!');
        _;
    }

    // init VPC settings
    constructor(uint256 _minKVerifiers, uint256 _maxKVerifiers, uint256 _minStake) public {
        settings[address(this)] = VPCsettings(_minKVerifiers, _maxKVerifiers, _minStake);
    }

    function getAvailableVerifiers() private view returns(uint256 K){
        for(uint256 i=0; i<=verifiersSet.length; i++){
            if(!verifiers[verifiersSet[i]].state){
                K+=1;
            }
        }
        return K;
    }

    function getKVerifiers(bytes32 channelId, uint256 K) private returns(bool){
        uint256 j=0;
        for(uint256 i=0; i<verifiersSet.length; i++){
            if(!verifiers[verifiersSet[i]].state && j <= K) {
                channels[channelId].verifiers.push(verifiersSet[i]);
            }
        }
        if(j==K){
            // set the verifier's current channel
            for (uint256 l=0; l <= channels[channelId].verifiers.length; l++){
                verifiers[channels[channelId].verifiers[l]].currChannelId = channelId;
                verifiers[channels[channelId].verifiers[l]].state = true;
            }
            return true;
        }
        return false;
    }

    function registerVerifier() public canRegisterVerifier() isValidStake() payable returns(bool){
        // TODO: move ether 'stake' to the contract
        verifiers[msg.sender] = Verifier(false, true, bytes32(0), msg.value);
        verifiersSet.push(msg.sender);
        emit VerifierRegistered(msg.sender);
        return true;
    }

    function deregisterVerifier() public canDeregisterVerifier() returns(bool) {
        verifiers[msg.sender].registered = false;
        // TODO: tranfer stake to the verifier address
        emit VerifierDeregistered(msg.sender);
        return true;
    }

    function initChannel(bytes32 channelId, uint256 KVerifiers, uint256 mOfN, address owner) public requireKVerifiers(KVerifiers, mOfN) isValidChannelId(channelId) returns(bool) {
        bytes32 proofId = keccak256(abi.encodePacked(channelId, block.number, msg.sender));
        proofs[proofId] = Proof(false, mOfN, channelId, new bytes32[](0), new bytes32[](0), new bytes[](0));
        channels[channelId] = Channel(true, owner, proofId,new address[](0));
        // TODO: set state of the verifier to 1 (busy)
        require(getKVerifiers(channelId, KVerifiers), 'Unable to initialize channel');
        emit ChannelInitialized(channelId, channels[channelId].verifiers, proofId);
        return true;
    }

    function terminateChannel(bytes32 channelId) public isPotValidated(channelId) returns(bool) {
        channels[channelId].state = false;
        return true;
    }

    function getChannelVerifiers(bytes32 channelId) public view returns(address[]) {
        return channels[channelId].verifiers;
    }

    function getChannelByProofId(bytes32 proofId) public view returns(bytes32) {
        return proofs[proofId].channelId;
    }

    function getMyCurrentChannel() public view returns(bytes32) {
        return verifiers[msg.sender].currChannelId;
    }

    function getProofIdByChannelId(bytes32 channelId) public view returns(bytes32) {
        return channels[channelId].proof;
    }

    function getProof(bytes32 proofId) public view returns(bool, bytes32, bytes32[]) {
        return (proofs[proofId].verified, proofs[proofId].channelId, proofs[proofId].proofHashs);
    }


    function isValidSignature(bytes32 hash, bytes signature, address verifier) private pure returns (bool){
        return (verifier == ECDSA.recover(hash, signature));
    }

    function submitProof(bytes32 channelId, string eot, bytes32[] merkleroot, bytes signature, bytes32 result) public canVerify(channelId) returns(bool) {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(channelId, merkleroot, eot, result)));
        if(isValidSignature(prefixedHash, signature, msg.sender)){
                proofs[channels[channelId].proof].signatures.push(signature);
                proofs[channels[channelId].proof].proofHashs.push(prefixedHash);
                proofs[channels[channelId].proof].results.push(result);
                emit ProofOfTraining(channelId, channels[channelId].proof, msg.sender, prefixedHash);
                return true;
        }
        return false;
    }

    function validateProof(bytes32 channelId) public returns (bool){
        uint256 kValidProofs = 0;
        for(uint256 i=0; i<proofs[channels[channelId].proof].signatures.length; i++){
            if(i < proofs[channels[channelId].proof].signatures.length -1){
                if(proofs[channels[channelId].proof].proofHashs[i] == proofs[channels[channelId].proof].proofHashs[i+1]) {
                    kValidProofs +=1;
                }
            }
        }
        if(proofs[channels[channelId].proof].MofNSigs == kValidProofs) {
            proofs[channels[channelId].proof].verified = true;
            // free verifiers
            for (uint j=0; j < channels[channelId].verifiers.length; j++){
                verifiers[channels[channelId].verifiers[j]].currChannelId = bytes32(0);
                verifiers[channels[channelId].verifiers[j]].state = false;
            }
            emit PoTValidated(channelId, channels[channelId].proof);
            return true;
        }
        return false;
    }
}