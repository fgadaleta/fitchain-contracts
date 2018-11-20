pragma solidity 0.4.25;

/**
@title Fitchain Commit Reveal Scheme
@author Team: Fitchain Team
*/

contract CommitReveal {

    struct Commitment{
        bool exist;
        bool vote;
        bytes32 hash;
        string value;
    }

    struct Setting{
        uint256 timeout;
        address owner;
    }

    mapping(bytes32 => mapping(address => Commitment)) commitments;
    mapping(bytes32 => Setting) settings;

    event CommitmentInitialized(bytes32 commitmentId, uint256 timeout, address[] voters);
    event CommitmentCommitted(bytes32 commitmentId, address voter);

    function setup(bytes32 _commitmentId, uint256 _timeout, address[] _voters) internal returns(bool){
        require(_timeout > 0, 'Indicating invalid timeout');
        settings[_commitmentId] = Setting(_timeout, msg.sender);
        emit CommitmentInitialized(_commitmentId, _timeout, _voters);
        return true;
    }

    function commit(bytes32 _commitmentId, bytes32 _hash) public returns(bool){
        require(!commitments[_commitmentId][msg.sender].exist, 'avoid replay attack');
        commitments[_commitmentId][msg.sender] = Commitment(true, false, _hash, new string(0));
        emit CommitmentCommitted(_commitmentId, msg.sender);
        return true;
    }

    function reveal(bytes32 _commitmentId, string _value, bool _vote) public returns(bool){
        require(!commitments[_commitmentId][msg.sender].exist);
        require(commitments[_commitmentId][msg.sender].hash == keccak256(abi.encodePacked(_vote, _value)));
        commitments[_commitmentId][msg.sender].vote = _vote;
        commitments[_commitmentId][msg.sender].value = _value;
        return true;
    }

}