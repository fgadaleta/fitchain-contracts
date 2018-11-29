pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './FitchainStake.sol';

/**
@title Fitchain Actors Registry
@author Team: Fitchain Team
*/

contract FitchainRegistry is Ownable {

    struct Registrant {
        bool exists;
        uint256 slots;
        uint256 maxSlots;
        address registryOwner;
    }

    mapping(address => Registrant) registrants;
    address[] actors;
    FitchainStake private staking;

    modifier onlyRegistryOwner(address registrant){
        require(registrants[registrant].registryOwner == msg.sender, 'invalid registry owner');
        _;
    }

    modifier onlyExist(address actor){
        require(registrants[actor].exists, 'Actor does not exists!');
        _;
    }

    modifier onlyFreeSlots(address actor){
        require(registrants[actor].slots == registrants[actor].maxSlots, 'registrant is busy, please free slots!');
        _;
    }

    modifier onlyNotExist(address actor) {
        require(!registrants[actor].exists, 'Actor already exists!');
        _;
    }

    constructor(address _stakeAddress) public {
        require(_stakeAddress != address(0), 'invalid address');
        staking = FitchainStake(_stakeAddress);
    }

    function register(address actor, uint256 slots, bytes32 stakeId, uint256 amount) public onlyNotExist(actor) returns(bool) {
        require(slots >= 1, 'invalid number of free slots');
        require(staking.stake(stakeId, actor, slots * amount));
        registrants[actor] = Registrant(true, slots, slots, msg.sender);
        addActorToRegistry(actor);
        return true;
    }

    function deregister(address actor, bytes32 stakeId) public onlyRegistryOwner(actor) onlyFreeSlots(actor) returns (bool) {
        uint256 amount = staking.getStakebyActor(stakeId, actor);
        require(amount > 0, 'indicating empty stake!');
        registrants[actor].exists = false;
        removeActorFromRegistry(actor);
        return staking.release(stakeId, actor, amount);
    }

    function slashActor(bytes32 stakeId, address actor, uint256 amount, bool decrementSlots) public onlyRegistryOwner(actor) onlyExist(actor) returns(bool){
        require(staking.slash(stakeId, actor, amount), 'unable to slash the actor');
        if(decrementSlots) {
            decrementActorSlots(actor);
            // decrement the max slots after slashing the stake
            registrants[actor].maxSlots -=1;
        }
        return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registrants[actor].exists;
    }

    function getActorFreeSlots(address actor) public view returns(uint256) {
        return registrants[actor].slots;
    }

    function getActorMaxSlots(address actor) public view returns(uint256) {
        return registrants[actor].maxSlots;
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

    function decrementActorSlots(address actor) public onlyRegistryOwner(actor) returns(bool){
        require(registrants[actor].slots > 0, 'invalid slots value');
        registrants[actor].slots -=1;
        if(registrants[actor].slots == 0){
            return removeActorFromRegistry(actor);
        }
        return true;
    }

    function incrementActorSlots(address actor) public onlyRegistryOwner(actor) returns(bool){
        require(registrants[actor].slots >=0, 'invalid slots value');
        if(registrants[actor].slots == 0){
            addActorToRegistry(actor);
        }
        registrants[actor].slots +=1;
        return true;
    }
}