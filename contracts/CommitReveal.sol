pragma solidity 0.4.25;

/**
@title Fitchain Commit Reveal Scheme
@author Team: Fitchain Team
*/

contract CommitReveal {

    struct Commitment{
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

    function setup(bytes32 _commitmentId, uint256 _timeout, address[] _voters) internal returns(bool){
        require(_timeout > 0, 'Indicating invalid timeout');
        settings[_commitmentId] = Setting(_timeout, msg.sender);
        emit CommitmentInitialized(_commitmentId, _timeout, _voters);
        return true;
    }

    function commit(bytes32 commitmentId, bytes32 hash) public returns(bool);

    function reveal(bytes32 commitmentId, string value, bool vote) public returns(bool);

}