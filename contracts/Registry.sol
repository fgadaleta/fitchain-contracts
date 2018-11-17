pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Fitchain Actors Registry
@author Team: Fitchain Team
*/

contract Registry is Ownable {

    struct Registrant {
        bool exists;
        bool isActive;
        uint256 slots;
        address[] actorTypes;
    }

    mapping(address => Registrant) registrants;
    mapping(address => bool) actorContractsTypes;
    mapping(address => address[]) contractType2Registrants;

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

    modifier canChangeSlots(address actor){
        address actorType = address(0);
        for (uint256 i=0; i<= registrants[actor].actorTypes.length; i++){
            if(msg.sender == registrants[actor].actorTypes[i]) actorType = registrants[actor].actorTypes[i];
        }
        require(actorType == msg.sender, 'unable to change the number of slots');
        _;
    }

    function registerActor(address[] actorTypes, bool active, uint256 slots) public onlyNotRegistered() onlyValidTypes(actorTypes) returns(bool) {
        //TODO: validate slots number and avoid integer overflow/underflow.
        registrants[msg.sender] = Registrant(true, active, slots, actorTypes);
        for(uint i=0; i<= actorTypes.length; i++){
            contractType2Registrants[actorTypes[i]].push(msg.sender);
        }
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
        contractType2Registrants[actorType].length = 0;
        return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function isActiveActor(address actor) public view returns(bool) {
        return registrants[actor].isActive;
    }

    function getActorActiveSlots(address actor) public view returns(uint256) {
        return registrants[actor].slots;
    }

    function isValidActorType(address actorType) public view returns(bool){
        return actorContractsTypes[actorType];
    }

    function getAvaliableRegistrantsByType(address actorType) public view returns(address[] actors) {
        uint256 j =0;
        for (uint256 i=0; i < contractType2Registrants[actorType].length; i++){
            if(registrants[contractType2Registrants[actorType][i]].slots >= 1)
            actors[j] = contractType2Registrants[actorType][i];
            j++;
        }
    }

    function decrementActorSlots(address actor) public canChangeSlots(actor) returns(bool){
        //TODO: this operation not secure
        registrants[actor].slots -=1;
    }

    function incrementActorSlots(address actor) public canChangeSlots(actor) returns(bool){
        //TODO: this operation not secure
        registrants[actor].slots +=1;
    }
}