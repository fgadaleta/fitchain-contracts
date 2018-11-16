pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Fitchain Actor Registry
@author Team: Fitchain Team
*/

contract Registry is Ownable {

    struct Registrant {
        bool exists;
        bool isActive;
        address[] actorTypes;
    }

    mapping(address => Registrant) registrants;
    mapping(address => bool) actorContractsTypes;

    modifier canDeregister() {
        require(!registrants[msg.sender].isActive, 'Registrant is active, can not dergister');
        _;
    }

    modifier onlyNotRegistered() {
        require(!registrants[msg.sender].exists, 'Registrant already exists');
        _;
    }

    modifier onlyRegistered() {
        require(registrants[msg.sender].exists, 'Registrant does not exist');
        _;
    }

    modifier canDeactivate(address actor) {
        require(actorContractsTypes[msg.sender], 'invalid call from actor type contract');
        require(registrants[actor].exists, 'Registrant does not exist');
        _;
    }

    modifier onlyValidTypes(address[] Types) {
        require(Types.length > 0, 'invalid number of types');
        for (uint256 i=0; i < Types.length; i++) {
            require(actorContractsTypes[Types[i]], 'invalid actor type');
        }
        _;
    }

    function registerActor(address[] actorTypes, bool active) public onlyNotRegistered() onlyValidTypes(actorTypes) returns(bool) {
        registrants[msg.sender] = Registrant(true, active, actorTypes);
        return true;
    }


    function deregisterActor() public onlyRegistered() canDeregister() returns (bool) {
        registrants[msg.sender].exists = false;
        return true;
    }

    function activateActor() public onlyRegistered() {
        registrants[msg.sender].isActive = true;
    }

    function deactivateActor(address actor) public canDeactivate(actor) returns(bool) {
        registrants[actor].isActive = false;
        return true;
    }

    function registerActorType(address actorType) public onlyOwner() returns(bool) {
        actorContractsTypes[actorType] = true;
        return true;
    }

    function deregisterActorType(address actorType) public onlyOwner() returns(bool) {
        actorContractsTypes[actorType] = false;
        return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function isActiveActor(address actor) public view returns(bool) {
        return registrants[actor].isActive;
    }

    function isValidActorType(address actorType) public view returns(bool){
        return actorContractsTypes[actorType];
    }
}