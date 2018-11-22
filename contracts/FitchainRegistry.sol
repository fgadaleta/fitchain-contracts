pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './FitchainStake.sol';

/**
@title Fitchain Actors Registry
@author Team: Fitchain Team
*/

contract FitchainRegistry is Ownable, FitchainStake {

    struct Registrant {
        bool exists;
        uint256 slots;
        uint256 maxSlots;
    }

    mapping(address => Registrant) registrants;
    address[] actors;


    modifier onlyFreeSlots(address actor){
        require(registrants[actor].slots == registrants[actor].maxSlots, 'registrant is busy, please free slots!');
        _;
    }

    modifier onlyNotExist(address actor) {
        require(!registrants[actor].exists, 'Actor already exists!');
        _;
    }

    function register(address actor, uint256 slots, bytes32 stakeId, uint256 amount) internal onlyNotExist(actor) returns(bool) {
        require(slots >= 1, 'invalid number of free slots');
        registrants[actor] = Registrant(true, slots, slots);
        stake(stakeId, actor, slots * amount);
        addActorToRegistry(actor);
        return true;
    }

    function deregister(address actor, bytes32 stakeId) internal onlyFreeSlots(actor) returns (bool) {
        uint256 amount = getStakebyActor(stakeId, actor);
        require(amount > 0, 'indicating empty stake!');
        registrants[actor].exists = false;
        removeActorFromRegistry(actor);
        return release(stakeId, actor, amount);
    }

    function slashActor(bytes32 stakeId, address actor, uint256 amount, bool decrementSlots) internal onlyNotExist(actor) returns(bool){
         require(slash(stakeId, actor, amount), 'unable to slash the actor');
         if(decrementSlots)
            decrementActorSlots(actor);
         return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function getActorFreeSlots(address actor) public view returns(uint256) {
        return registrants[actor].slots;
    }

    function removeActorFromRegistry(address actor)  private returns(bool) {
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

    function addActorToRegistry(address actor) private returns(bool) {
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
            return removeActorFromRegistry(actor);
        }
        return true;
    }

    function incrementActorSlots(address actor) internal returns(bool){
        require(registrants[actor].slots >=0, 'invalid slots value');
        if(registrants[actor].slots == 0){
            addActorToRegistry(actor);
        }
        registrants[actor].slots +=1;
        return true;
    }
}