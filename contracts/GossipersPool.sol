pragma solidity ^0.4.25;

import 'openzeppelin-solidity/contracts/cryptography/ECDSA.sol';
import './FitchainRegistry.sol';

/**
@title Fitchain Gossipers Pool Contract
@author Team: Fitchain Team
*/

contract GossipersPool {

    // lighting channels
    struct Channel {
        bool state;
        address owner;
        bytes32 proof;
        address[] gossipers;
    }

    // proof of training
    struct Proof {
        bool isVerified;
        uint256 MofNSigs;
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

    mapping(bytes32 => Channel) channels;
    mapping(bytes32 => Proof) proofs;
    mapping(address => GPCsettings) settings;
    FitchainRegistry private registry;



    // events
    event ChannelInitialized(bytes32 channelId, address[] gossipers, bytes32 proofId);
    event PoTSubmitted(bytes32 channelId, bytes32 proofId, address verifier, bytes32 proofHash);
    event PoTValidated(bytes32 channelId, bytes32 proofId, bool state, uint256 submittedProofs);

    // access control modifiers
    modifier requireKGossipers(uint256 KGossipers, uint256 mOfN) {
        require(settings[address(this)].minKGossipers <= KGossipers, 'indicating small number of gossipers');
        require(settings[address(this)].maxKGossipers >= KGossipers, 'indicating large number of gossipers');
        require(getAvailableGossipers().length >= KGossipers, 'K gossipers are not available');
        require(KGossipers >= mOfN, 'Invalid channel initialization input parameters');
        _;
    }

    modifier isValidChannelId(bytes32 channelId) {
        require(!channels[channelId].state, 'Channel already exists');
        _;
    }

    modifier onlyValidStake(uint256 amount){
        require(amount >= settings[address(this)].minStake);
        _;
    }

    modifier canVerify(bytes32 channelId) {
        bool state = false;
        for(uint256 i=0; i< channels[channelId].gossipers.length; i++){
            if(msg.sender == channels[channelId].gossipers[i]) state=true;
        }
        require(state, 'unable to verify the proof, access denied!');
        _;
    }

    modifier isPotValidated(bytes32 channelId) {
        require(proofs[channels[channelId].proof].isVerified, 'Unable to terminate channel, PoT not validated yet!');
        _;
    }

    // init GPC settings
    constructor(address _registryAddress, uint256 _minKGossipers, uint256 _maxKGossipers, uint256 _minStake) public {
        require(_registryAddress != address(0), 'invalid registry contract address');
        settings[address(this)] = GPCsettings(_minKGossipers, _maxKGossipers, _minStake);
        registry = FitchainRegistry(_registryAddress);
    }

    function registerGossiper(uint256 amount, uint256 slots) public onlyValidStake(amount) returns(bool){
        return registry.register(msg.sender, slots, keccak256(abi.encodePacked(address(this))), amount);
    }

    function isRegisteredGossiper(address gossiper) public view returns(bool){
        require(gossiper != address(0), 'invalid gossiper address');
        return registry.isActorRegistered(gossiper);
    }

    function deregisterGossiper() public returns(bool){
        return registry.deregister(msg.sender,  keccak256(abi.encodePacked(address(this))));
    }

    function getAvailableGossipers() public view returns(address[]){
        return registry.getAvaliableRegistrants();
    }

    function getKGossipers(bytes32 channelId, uint256 K) private returns(uint256){
        address[] memory gossipersSet = getAvailableGossipers();
        for(uint256 i=0; i< K; i++){
            channels[channelId].gossipers.push(gossipersSet[i]);
        }
        return channels[channelId].gossipers.length;
    }


    function initChannel(bytes32 channelId, uint256 KGossipers, uint256 mOfN, address owner) public requireKGossipers(KGossipers, mOfN) isValidChannelId(channelId) returns(bool) {
        bytes32 proofId = keccak256(abi.encodePacked(channelId, block.number, msg.sender));
        proofs[proofId] = Proof(false, mOfN, channelId, new bytes32[](0), new bytes32[](0), new bytes[](0));
        channels[channelId] = Channel(true, owner, proofId,new address[](0));
        require(getKGossipers(channelId, KGossipers) == KGossipers , 'Unable to initialize channel');
        for (uint256 i=0; i<channels[channelId].gossipers.length; i++){
            registry.decrementActorSlots(channels[channelId].gossipers[i]);
        }
        emit ChannelInitialized(channelId, channels[channelId].gossipers, proofId);
        return true;
    }

    function terminateChannel(bytes32 channelId) public isPotValidated(channelId) returns(bool) {
        if(!channels[channelId].state) return true;
        channels[channelId].state = false;
        return true;
    }

    function getChannelGossipers(bytes32 channelId) public view returns(address[]) {
        return channels[channelId].gossipers;
    }

    function getChannelByProofId(bytes32 proofId) public view returns(bytes32) {
        return proofs[proofId].channelId;
    }

    function getProofIdByChannelId(bytes32 channelId) public view returns(bytes32) {
        return channels[channelId].proof;
    }

    function getProof(bytes32 channelId) public view returns(bool, bytes32, bytes32[]) {
        bytes32 proofId = channels[channelId].proof;
        return (proofs[proofId].isVerified, proofs[proofId].channelId, proofs[proofId].proofHashs);
    }

    function isValidProof(bytes32 channelId) public view returns(bool) {
        return proofs[channels[channelId].proof].isVerified;
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
            emit PoTSubmitted(channelId, channels[channelId].proof, msg.sender, prefixedHash);
            return true;
        }
        return false;
    }

    function freeChannelSlots(bytes32 channelId) private returns(bool){
        for (uint j=0; j < channels[channelId].gossipers.length; j++){
            registry.incrementActorSlots(channels[channelId].gossipers[j]);
            //TODO: free the gossiper stake
        }
        return true;
    }
    function validateProof(bytes32 channelId) public returns (bool){
        uint256 kValidProofs = 0;
        for(uint256 i=0; i<proofs[channels[channelId].proof].signatures.length; i++){
            if(i < proofs[channels[channelId].proof].signatures.length -1){
                if(proofs[channels[channelId].proof].proofHashs[i] == proofs[channels[channelId].proof].proofHashs[i+1]) {
                    kValidProofs +=1;
                }
            }else{
                if(proofs[channels[channelId].proof].proofHashs[i] == proofs[channels[channelId].proof].proofHashs[i-1]){
                    kValidProofs +=1;
                }
            }
        }
        if(proofs[channels[channelId].proof].MofNSigs <= kValidProofs) {
            proofs[channels[channelId].proof].isVerified = true;
            // free gossipers
            require(freeChannelSlots(channelId), 'unable to free channel');
            emit PoTValidated(channelId, channels[channelId].proof, true, kValidProofs);
            return true;
        }
        emit PoTValidated(channelId, channels[channelId].proof, false, kValidProofs);
        return false;
    }

    function getChannelOwner(bytes32 channelId) public view returns(address) {
        return channels[channelId].owner;
    }

    function isChannelTerminated(bytes32 channelId) public view returns (bool) {
        if (channels[channelId].state) return false;
        return true;
    }
}