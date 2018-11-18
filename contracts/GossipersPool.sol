pragma solidity ^0.4.25;

import 'openzeppelin-solidity/contracts/cryptography/ECDSA.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './Registry.sol';
import './Stake.sol';

/**
@title Fitchain Gossipers Pool Contract
@author Team: Fitchain Team
*/

contract GossipersPool is Registry, Stake {

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

    mapping(bytes32 => Channel) channels;
    mapping(bytes32 => Proof) proofs;
    mapping(address => GPCsettings) settings;

    // events
    event ChannelInitialized(bytes32 channelId, address[] gossipers, bytes32 proofId);
    event PoTSubmitted(bytes32 channelId, bytes32 proofId, address verifier, bytes32 proofHash);
    event PoTValidated(bytes32 channelId, bytes32 proofId);


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

    modifier isValidStake(){
        require(msg.value >= settings[address(this)].minStake);
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

    // init VPC settings
    constructor(uint256 _minKGossipers, uint256 _maxKGossipers, uint256 _minStake) public {
        settings[address(this)] = GPCsettings(_minKGossipers, _maxKGossipers, _minStake);
    }

    function getAvailableGossipers() private view returns(address[]){
        return super.getAvaliableRegistrants();
    }

    function getKGossipers(bytes32 channelId, uint256 K) private returns(uint256){
        address [] memory gossipersSet = getAvailableGossipers();
        for(uint256 i=0; i< K; i++){
            channels[channelId].gossipers.push(gossipersSet[i]);
            // TODO: decrease the number of the available slots for the gossiper
            super.decrementActorSlots(gossipersSet[i]);
        }
        return channels[channelId].gossipers.length;
    }


    function initChannel(bytes32 channelId, uint256 KVerifiers, uint256 mOfN, address owner) public requireKGossipers(KVerifiers, mOfN) isValidChannelId(channelId) returns(bool) {
        bytes32 proofId = keccak256(abi.encodePacked(channelId, block.number, msg.sender));
        proofs[proofId] = Proof(false, mOfN, channelId, new bytes32[](0), new bytes32[](0), new bytes[](0));
        channels[channelId] = Channel(true, owner, proofId,new address[](0));
        // TODO: set state of the verifier to 1 (busy)
        require(getKGossipers(channelId, KVerifiers) == KVerifiers , 'Unable to initialize channel');
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

    function getProofIdByChannelId(bytes32 channelId) public view returns(bytes32) {
        return channels[channelId].proof;
    }

    function getProof(bytes32 proofId) public view returns(bool, bytes32, bytes32[]) {
        return (proofs[proofId].isVerified, proofs[proofId].channelId, proofs[proofId].proofHashs);
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
            proofs[channels[channelId].proof].isVerified = true;
            // free gossipers
            for (uint j=0; j < channels[channelId].gossipers.length; j++){
                super.incrementActorSlots(channels[channelId].gossipers[i]);
                //TODO: free the gossiper stake
            }
            emit PoTValidated(channelId, channels[channelId].proof);
            return true;
        }
        return false;
    }
}