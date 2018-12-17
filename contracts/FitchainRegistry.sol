pragma solidity ^0.4.25;

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
    }
    // RegistryOwner -> Actor -> RegistrantStruct
    mapping(address => mapping(address => Registrant)) registry;
    mapping(address => address[]) actors;
    FitchainStake private staking;

    modifier onlyRegistryOwner(address actor){
        require(registry[msg.sender][actor].exists, 'invalid registry owner');
        _;
    }

    modifier onlyExist(address actor){
        require(registry[msg.sender][actor].exists, 'invalid registry owner');
        _;
    }

    modifier onlyFreeSlots(address actor){
        require(registry[msg.sender][actor].slots == registry[msg.sender][actor].maxSlots, 'registrant is busy, please free some slots');
        _;
    }

    modifier onlyNotExist(address actor) {
        require(!registry[msg.sender][actor].exists, 'Actor already exists!');
        _;
    }

    constructor(address _stakeAddress) public {
        require(_stakeAddress != address(0), 'invalid address');
        staking = FitchainStake(_stakeAddress);
    }

    function register(address actor, uint256 slots, bytes32 stakeId, uint256 amount) public onlyNotExist(actor) returns(bool) {
        require(slots >= 1, 'invalid number of free slots');
        require(staking.stake(stakeId, actor, slots * amount));
        registry[msg.sender][actor] = Registrant(true, slots, slots);
        addActorToRegistry(actor, msg.sender);
        return true;
    }

    function deregister(address actor, bytes32 stakeId) public onlyRegistryOwner(actor) onlyFreeSlots(actor) returns (bool) {
        uint256 amount = staking.getStakebyActor(stakeId, actor);
        require(amount > 0, 'indicating empty stake!');
        registry[msg.sender][actor].exists = false;
        removeActorFromRegistry(actor, msg.sender);
        return staking.release(stakeId, actor, amount);
    }

    function slashActor(bytes32 stakeId, address actor, uint256 amount, bool decrementSlots) public onlyRegistryOwner(actor) onlyExist(actor) returns(bool){
        require(staking.slash(stakeId, actor, amount), 'unable to slash the actor');
        if(decrementSlots) {
            decrementActorSlots(actor);
            // decrement the max slots after slashing the stake
            registry[msg.sender][actor].maxSlots -=1;
        }
        return true;
    }

    function isActorRegistered(address actor) public view returns(bool) {
        return registry[msg.sender][actor].exists;
    }

    function getActorFreeSlots(address actor) public view returns(uint256) {
        return registry[msg.sender][actor].slots;
    }

    function getActorMaxSlots(address actor) public view returns(uint256) {
        return registry[msg.sender][actor].maxSlots;
    }

    function removeActorFromRegistry(address actor, address owner)  private returns(bool) {
        // This function is prone to gas limit errors
        for(uint256 j=0; j<actors[owner].length; j++){
            if(actor == actors[owner][j]){
                for (uint i=j; i< actors[owner].length-1; i++){
                    actors[owner][i] = actors[owner][i+1];
                }
                actors[owner].length--;
                return true;
            }
        }
        return false;
    }

    function addActorToRegistry(address actor, address owner) private returns(bool) {
        actors[owner].push(actor);
        return true;
    }

    function getAvaliableRegistrants() public view returns(address[]) {
        return actors[msg.sender];
    }

    function decrementActorSlots(address actor) public onlyRegistryOwner(actor) returns(bool){
        require(registry[msg.sender][actor].slots > 0, 'invalid slots value');
        registry[msg.sender][actor].slots -=1;
        if(registry[msg.sender][actor].slots == 0){
            return removeActorFromRegistry(actor, msg.sender);
        }
        return true;
    }

    function incrementActorSlots(address actor) public onlyRegistryOwner(actor) returns(bool){
        require(registry[msg.sender][actor].slots >=0, 'invalid slots value');
        if(registry[msg.sender][actor].slots == 0){
            addActorToRegistry(actor, msg.sender);
        }
        registry[msg.sender][actor].slots +=1;
        return true;
    }
}