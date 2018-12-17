pragma solidity ^0.4.25;

import './FitchainToken.sol';
/**
@title Fitchain Stake Contract
@author Team: Fitchain Team
*/

contract FitchainStake {

    struct Stake{
        address owner;
        mapping(address=>uint256) actors;
    }

    mapping(bytes32 => Stake) stakes;
    FitchainToken private token;

    modifier onlyStakeOwner(bytes32 stakeId){
        require(stakes[stakeId].owner == msg.sender, 'invalid stake owner');
        _;
    }

    event Staking(address sender, address receiver, uint256 amount, bool state);

    constructor(address _tokenAddress) public {
        require(_tokenAddress != address(0), 'Invalid address');
        token = FitchainToken(_tokenAddress);
    }

    function stake(bytes32 stakeId, uint256 amount) public returns(bool){
        token.allowance(msg.sender, address(this));
        if(token.transferFrom(msg.sender, address(this), amount)){
            stakes[stakeId].actors[msg.sender] += amount;
            stakes[stakeId].owner = msg.sender;
            emit Staking(msg.sender, address(this), amount, true);
            return true;
        }
        emit Staking(msg.sender, address(this), amount, false);
        return false;
    }

    function stake(bytes32 stakeId, address actor, uint256 amount) public returns(bool){
        token.allowance(msg.sender, address(this));
        require(token.balanceOf(actor) >= amount, 'insufficient fund');
        if(token.transferFrom(actor, address(this), amount)){
            stakes[stakeId].actors[actor] += amount;
            stakes[stakeId].owner = msg.sender;
            return true;
        }
        return false;
    }

    function getStakebyActor(bytes32 stakeId, address actor) public view returns(uint256){
        return stakes[stakeId].actors[actor];
    }

    function slash(bytes32 stakeId, address actor, uint256 amount) public onlyStakeOwner(stakeId) returns(bool){
        require(stakes[stakeId].actors[actor] > amount, 'insufficient fund');
        stakes[stakeId].actors[actor] -= amount;
        //TODO: distribute this amount as a reward for other actors in the same pool
        return true;
    }

    function release(bytes32 stakeId, address actor, uint256 amount) public onlyStakeOwner(stakeId) returns(bool){
        require(stakes[stakeId].actors[actor] >= amount, 'invalid release token amount');
        require(token.transfer(actor, amount), 'unable to transfer token to the actor!');
        stakes[stakeId].actors[actor] -= amount;
        return true;
    }
}