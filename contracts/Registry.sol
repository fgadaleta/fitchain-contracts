pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Fitchain Actors Registry
@author Team: Fitchain Team
*/

contract FitchainRegistry is Ownable {

    struct Registrant {
        bool exists;
        uint256 slots;
        uint256 maxSlots;
    }

    mapping(address => Registrant) registrants;
    address[] actors;


    modifier onlyFreeSlots(){
        require(registrants[msg.sender].slots == registrants[msg.sender].maxSlots, 'registrant is busy, please free slots!');
        _;
    }

    modifier onlyNotExist() {
        require(!registrants[msg.sender].exists, 'Actor already exists!');
        _;
    }

    function register(uint256 slots) public onlyNotExist() returns(bool) {
        require(slots >= 1, 'invalid number of free slots');
        registrants[msg.sender] = Registrant(true, slots, slots);
        actors.push(msg.sender);
        return true;
    }

    function deregister() public onlyFreeSlots() returns (bool) {
        registrants[msg.sender].exists = false;
        return removeActor(msg.sender);
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function getActorFreeSlots(address actor) public view returns(uint256) {
        return registrants[actor].slots;
    }

    function removeActor(address actor)  private returns(bool) {
        for(uint256 j=0; j<actors.length; j++){
            if(actor == actors[j]){
                for (uint i=j; i< actors.length-1; i++){
                    actors[i] = actors[i+1];
                }
                actors.length--;
                return true;
            }
        }
        return false;
    }

    function addActor(address actor) private returns(bool) {
        actors.push(actor);
        return true;
    }

    function getAvaliableRegistrants() public view returns(address[]) {
        return actors;
    }

    function decrementActorSlots(address actor) internal returns(bool){
        require(registrants[actor].slots > 0, 'invalid slots value');
        registrants[actor].slots -=1;
        if(registrants[actor].slots == 0){
            return removeActor(actor);
        }
        return true;
    }

    function incrementActorSlots(address actor) internal returns(bool){
        require(registrants[actor].slots >=0, 'invalid slots value');
        if(registrants[actor].slots == 0){
            addActor(actor);
        }
        registrants[actor].slots +=1;
        return true;
    }
}