pragma solidity 0.4.25;

import 'github.com/openzeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Fitchain Actor Registry
@author Team: Fitchain Team
*/

contract Registry is Ownable {

    struct Registrant {
        bool exists;
        bool isAvailable;
        uint8 actorType;
    }

    mapping(address => Registrant) registrants;

    modifier canDeregister() {
        require(!registrants[msg.sender].isAvailable, 'Registrant is busy, can not dergister');
        _;
    }

    modifier isNotRegistered() {
        require(!registrants[msg.sender].exists, 'Registrant already exists');
        _;
    }

    function registerActor(uint8 actorType) public isNotRegistered() returns(bool) {
        registrants[msg.sender] = Registrant(true, false, actorType);
        return true;
    }


    function deregisterActor() public canDeregister() returns (bool) {
        registrants[msg.sender].exists = false;
        return true;
    }

}