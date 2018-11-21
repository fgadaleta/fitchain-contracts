pragma solidity 0.4.25;

/**
@title Fitchain Commit Reveal Scheme
@author Team: Fitchain Team
*/

contract CommitReveal {

    struct Commitment{
        bool exist;
        bool isRevealed;
        bool vote;
        bytes32 hash;
        string value;
    }

    struct Setting{
        uint256 commitTimeout;
        uint256 revealTimeout;
        address owner;
    }

    mapping(bytes32 => mapping(address => Commitment)) commitments;
    mapping(bytes32 => Setting) settings;
    mapping (bytes32 => uint256) commitmentsCount;

    // events
    event CommitmentInitialized(bytes32 commitmentId, uint256 commitTime, uint256 revealingTime, address[] voters);
    event CommitmentCommitted(bytes32 commitmentId, address voter);
    event CommitmentRevealed(bytes32 commitmentId, address voter, uint256 revealingTime);

    // modifiers
    modifier onlyAfterReveal(bytes32 commitmentId){
        require(settings[commitmentId].revealTimeout >= block.timestamp, 'commitment not revealed yet');
        _;
    }


    function setup(bytes32 _commitmentId, uint256 _commitTimeout, uint256 _revealTimeout, address[] _voters) internal returns(bool){
        require(_commitTimeout >= 20 && _revealTimeout >= 20, 'Indicating invalid commit timeout');
        settings[_commitmentId] = Setting(_commitTimeout + block.timestamp, _commitTimeout + _revealTimeout + block.timestamp, msg.sender);
        commitmentsCount[_commitmentId] = 0;
        emit CommitmentInitialized(_commitmentId, _commitTimeout + block.timestamp,  _commitTimeout + _revealTimeout + block.timestamp, _voters);
        return true;
    }

    function commit(bytes32 _commitmentId, bytes32 _hash) public returns(bool){
        require(!commitments[_commitmentId][msg.sender].exist, 'avoid replay attack');
        require(settings[_commitmentId].commitTimeout > block.timestamp, 'Invalid commit time');
        commitments[_commitmentId][msg.sender] = Commitment(true, false, false,_hash, new string(0));
        emit CommitmentCommitted(_commitmentId, msg.sender);
        return true;
    }

    function reveal(bytes32 _commitmentId, string _value, bool _vote) public returns(bool){
        require(commitments[_commitmentId][msg.sender].exist, 'Commitment is not exist!');
        require(!commitments[_commitmentId][msg.sender].isRevealed, 'Indicating replay attack');
        require(settings[_commitmentId].revealTimeout > block.timestamp && settings[_commitmentId].commitTimeout < block.timestamp, 'invalid reveal timing!');
        require(commitments[_commitmentId][msg.sender].hash == keccak256(abi.encodePacked(_vote, _value)), 'invalid commitment preimage');
        commitments[_commitmentId][msg.sender].vote = _vote;
        commitments[_commitmentId][msg.sender].value = _value;
        commitments[_commitmentId][msg.sender].isRevealed = true;
        emit CommitmentRevealed(_commitmentId, msg.sender, settings[_commitmentId].revealTimeout);
        return true;
    }

    function getCommitmentResult(bytes32 _commitmentId) internal onlyAfterReveal(_commitmentId) returns(address[] winners, address[]losers){
        //TODO: check if commitment are valid or not
        return (winners, losers);
    }

    function getRevealTimeout(bytes32 _commitmentId) public view returns(uint256) {
        return settings[_commitmentId].revealTimeout;
    }

    function getCommitTimeout(bytes32 _commitmentId) public view returns(uint256) {
        return settings[_commitmentId].commitTimeout;
    }
}