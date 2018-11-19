pragma solidity 0.4.25;

import './FitchainToken.sol';
/**
@title Fitchain Stake Contract
@author Team: Fitchain Team
*/

contract FitchainStake is FitchainToken {

    struct Stake{
        mapping(address=>uint256) actors;
    }

    mapping(bytes32 => Stake) stakes;

    function stake(bytes32 stakeId, uint256 amount) public returns(bool){
        require(super.balanceOf(msg.sender) > amount, 'insufficient fund');
        if(super.transferFrom(msg.sender, address(this), amount)){
            stakes[stakeId].actors[msg.sender] += amount;
            return true;
        }
        return false;
    }

    function stake(bytes32 stakeId, address actor, uint256 amount) internal returns(bool){
        require(super.balanceOf(actor) > amount, 'insufficient fund');
        if(super.transferFrom(actor, address(this), amount)){
            stakes[stakeId].actors[actor] += amount;
            return true;
        }
        return false;
    }

    function getStakebyActor(bytes32 stakeId, address actor) public view returns(uint256){
        return stakes[stakeId].actors[actor];
    }

    function slash(bytes32 stakeId, address actor, uint256 amount) internal returns(bool){
        require(stakes[stakeId].actors[actor] > amount, 'insufficient fund');
        stakes[stakeId].actors[actor] -= amount;
        //TODO: distribute this amount as a reward for other actors in the same pool
        return true;
    }

    function release(bytes32 stakeId, address actor, uint256 amount) internal returns(bool){
        require(stakes[stakeId].actors[actor] >= amount, 'invalid release token amount');
        stakes[stakeId].actors[actor] -= amount;
        super.transfer(actor, amount);
        return true;
    }
}