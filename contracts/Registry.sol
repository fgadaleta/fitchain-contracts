pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Fitchain Actors Registry
@author Team: Fitchain Team
*/

contract Registry is Ownable {

    struct Registrant {
        bool exists;
        uint256 slots;
        uint256 maxSlots;
    }

    mapping(address => Registrant) registrants;
    address[] registrantSet;


    modifier onlyAllFreeSlots(){
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
        registrantSet.push(msg.sender);
        return true;
    }

    function deregister() public onlyAllFreeSlots() returns (bool) {
        registrants[msg.sender].exists = false;
        //TODO: free registrantSet
        return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function getActorFreeSlots(address actor) public view returns(uint256) {
        return registrants[actor].slots;
    }

    function getAvaliableRegistrants() public view returns(address[] actors) {
        uint256 j=0;
        for (uint256 i=0; i < registrantSet.length; i++){
            if(registrants[registrantSet[i]].slots >= 1)
                actors[j] = registrantSet[i];
                j++;
        }
    }

    function decrementActorSlots(address actor) internal returns(bool){
        require(registrants[actor].slots > 0, 'invalid slots value');
        registrants[actor].slots -=1;
        return true;
    }

    function incrementActorSlots(address actor) internal returns(bool){
        registrants[actor].slots +=1;
        return true;
    }
}