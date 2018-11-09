pragma solidity ^0.4.25;

import 'openzeppelin-solidity/contracts/cryptography/ECDSA.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract VPC is Ownable {

    // Fitchain PoT verifier
    struct Verifier {
        bool state; // 0 avaialble
        bool registered;
        uint256 stake;
    }

    // lighting channels
    struct Channel {
        bool state;
        bytes32 proof;
        address[] verifiers;
    }

    // proof of training
    struct Proof {
        bool verified;
        bytes32 channelId;
        string endOfTrainingTrx;
        bytes32[] merkleroot;
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
    event ChannelInitialized(bytes32 channelId, address[] verifiers);
    event VerifierRegistered(address verifier, bool state);
    event VerifierDeregistered(address verifeir, bool state);


    // access control modifiers
    modifier requireKVerifiers(uint256 KVerifiers) {
        require(settings[address(this)].minKVerifiers <= KVerifiers, 'indicating small number of verifiers');
        require(settings[address(this)].maxKVerifiers >= KVerifiers, 'indicating large number of verifiers');
        require(getAvailableVerifiers() == KVerifiers, 'K verifiers are not available');
        _;
    }

    modifier isValidChannelId(bytes32 channelId) {
        require(!channels[channelId].state, 'Channel already exists');
        _;
    }

    modifier isNotRegistered() {
        require(!verifiers[msg.sender].registered, 'Verifier already registered');
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
        if(j==K) return true;
        return false;
    }

    function registerVerifier() public isNotRegistered() payable returns(bool){
        // TODO: check stake modifier
        verifiers[msg.sender] = Verifier(false, true, msg.value);
        verifiersSet.push(msg.sender);
        emit VerifierRegistered(msg.sender, true);
        return true;
    }

    function initChannel(bytes32 channelId, uint256 KVerifiers) public requireKVerifiers(KVerifiers) isValidChannelId(channelId) returns(bool) {
        bytes32 proofId = keccak256(abi.encodePacked(channelId, block.number));
        proofs[proofId] = Proof(false, channelId, new string(0), new bytes32[](0), new bytes[](0));
        channels[channelId] = Channel(true, proofId, new address[](0));
        require(getKVerifiers(channelId, KVerifiers), 'Unable to initialize channel');
        emit ChannelInitialized(channelId, channels[channelId].verifiers);
        return true;
    }

}