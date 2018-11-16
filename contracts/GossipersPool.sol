pragma solidity ^0.4.25;

import 'github.com/openzeppelin/openzeppelin-solidity/contracts/cryptography/ECDSA.sol';
import 'github.com/openzeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './FitchainRegistry.sol';

/**
@title Fitchain Gossipers Pool Contract
@author Team: Fitchain Team
*/

contract GossipersPool is Ownable {

    // Fitchain PoT Gossipers
    struct Gossiper {
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
        address[] gossipers;
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
    struct GPCsettings {
        uint256  minKGossipers;
        uint256  maxKGossipers;
        uint256  minStake;
    }

    mapping(address => Gossiper) gossipers;
    mapping(bytes32 => Channel) channels;
    mapping(bytes32 => Proof) proofs;
    mapping(address => GPCsettings) settings;
    address[] private gossipersSet;

    Registry private registry;

    // events
    event GossiperRegistered(address gossiper);
    event GossiperDeregistered(address gossiper);
    event ChannelInitialized(bytes32 channelId, address[] gossipers, bytes32 proofId);
    event ProofOfTraining(bytes32 channelId, bytes32 proofId, address verifier, bytes32 proofHash);
    event PoTValidated(bytes32 channelId, bytes32 proofId);


    // access control modifiers
    modifier requireKGossipers(uint256 KGossipers, uint256 mOfN) {
        require(settings[address(this)].minKGossipers <= KGossipers, 'indicating small number of gossipers');
        require(settings[address(this)].maxKGossipers >= KGossipers, 'indicating large number of gossipers');
        require(getAvailableGossipers() == KGossipers, 'K gossipers are not available');
        require(KGossipers >= mOfN, 'Invalid channel initialization input parameters');
        _;
    }

    modifier isValidChannelId(bytes32 channelId) {
        require(!channels[channelId].state, 'Channel already exists');
        _;
    }

    modifier canRegisterGossiper() {
        require(!gossipers[msg.sender].registered, 'Gossiper already registered');
        _;
    }

    modifier canDeregisterGossiper() {
        require(gossipers[msg.sender].currChannelId == bytes32(0), 'Gossiper curretly part of channel');
        require(!gossipers[msg.sender].state, 'Can not deregister gossiper is busy');
        _;
    }

    modifier isValidStake(){
        require(msg.value >= settings[address(this)].minStake);
        _;
    }

    modifier canVerify(bytes32 channelId) {
        require(gossipers[msg.sender].currChannelId == channelId, 'invalid channelId!');
        _;
    }

    modifier isPotValidated(bytes32 channelId) {
        require(proofs[channels[channelId].proof].verified, 'Unable to terminate channel, PoT not validated yet!');
        _;
    }

    // init VPC settings
    constructor(uint256 _minKGossipers, uint256 _maxKGossipers, uint256 _minStake, address _registry) public {
        require(_registry != address(0), 'Invalid registry contract address');
        settings[address(this)] = GPCsettings(_minKGossipers, _maxKGossipers, _minStake);
        registry = Registry(_registry);
    }

    function getAvailableGossipers() private view returns(uint256 K){
        for(uint256 i=0; i<=gossipersSet.length; i++){
            if(!gossipers[gossipersSet[i]].state){
                K+=1;
            }
        }
        return K;
    }

    function getKVerifiers(bytes32 channelId, uint256 K) private returns(bool){
        uint256 j=0;
        for(uint256 i=0; i<gossipersSet.length; i++){
            if(!gossipers[gossipersSet[i]].state && j <= K) {
                channels[channelId].gossipers.push(gossipersSet[i]);
            }
        }
        if(j==K){
            // set the verifier's current channel
            for (uint256 l=0; l <= channels[channelId].gossipers.length; l++){
                gossipers[channels[channelId].gossipers[l]].currChannelId = channelId;
                gossipers[channels[channelId].gossipers[l]].state = true;
            }
            return true;
        }
        return false;
    }

    function registerGossiper() public canRegisterGossiper() isValidStake() payable returns(bool){
        // TODO: move ether 'stake' to the contract
        gossipers[msg.sender] = Gossiper(false, true, bytes32(0), msg.value);
        gossipersSet.push(msg.sender);
        emit GossiperRegistered(msg.sender);
        return true;
    }

    function deregisterGossiper() public canDeregisterGossiper() returns(bool) {
        gossipers[msg.sender].registered = false;
        // TODO: tranfer stake to the gossiper address
        emit GossiperDeregistered(msg.sender);
        return true;
    }

    function initChannel(bytes32 channelId, uint256 KVerifiers, uint256 mOfN, address owner) public requireKGossipers(KVerifiers, mOfN) isValidChannelId(channelId) returns(bool) {
        bytes32 proofId = keccak256(abi.encodePacked(channelId, block.number, msg.sender));
        proofs[proofId] = Proof(false, mOfN, channelId, new bytes32[](0), new bytes32[](0), new bytes[](0));
        channels[channelId] = Channel(true, owner, proofId,new address[](0));
        // TODO: set state of the verifier to 1 (busy)
        require(getKVerifiers(channelId, KVerifiers), 'Unable to initialize channel');
        emit ChannelInitialized(channelId, channels[channelId].gossipers, proofId);
        return true;
    }

    function terminateChannel(bytes32 channelId) public isPotValidated(channelId) returns(bool) {
        channels[channelId].state = false;
        return true;
    }

    function getChannelVerifiers(bytes32 channelId) public view returns(address[]) {
        return channels[channelId].gossipers;
    }

    function getChannelByProofId(bytes32 proofId) public view returns(bytes32) {
        return proofs[proofId].channelId;
    }

    function getMyCurrentChannel() public view returns(bytes32) {
        return gossipers[msg.sender].currChannelId;
    }

    function getProofIdByChannelId(bytes32 channelId) public view returns(bytes32) {
        return channels[channelId].proof;
    }

    function getProof(bytes32 proofId) public view returns(bool, bytes32, bytes32[]) {
        return (proofs[proofId].verified, proofs[proofId].channelId, proofs[proofId].proofHashs);
    }


    function isValidSignature(bytes32 hash, bytes signature, address gossiper) private pure returns (bool){
        return (gossiper == ECDSA.recover(hash, signature));
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
            // free gossipers
            for (uint j=0; j < channels[channelId].gossipers.length; j++){
                gossipers[channels[channelId].gossipers[j]].currChannelId = bytes32(0);
                gossipers[channels[channelId].gossipers[j]].state = false;
            }
            emit PoTValidated(channelId, channels[channelId].proof);
            return true;
        }
        return false;
    }
}