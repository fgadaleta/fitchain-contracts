pragma solidity 0.4.25;

import './FitchainRegistry.sol';
import './CommitReveal.sol';
import './FitchainHelper.sol';

/**
@title Fitchain Model Verifiers Pool Contract (VPC)
@author Team: Fitchain Team
*/

contract VerifiersPool is FitchainHelper, CommitReveal, FitchainRegistry  {

    struct Challenge{
        address owner;
    }

    struct VPCSetting{
        uint256 minKVerifiers;
        uint256 minStake;
    }

    mapping (address => VPCSetting) VPCsettings;

    // modifiers
    modifier onlyValidStake(uint256 amount){
        require(amount >= VPCsettings[address(this)].minStake);
        _;
    }

    // init VPC settings
    constructor(uint256 _minKVerifiers, uint256 _minStake) public {
        VPCsettings[address(this)] = VPCSetting(_minKVerifiers, _minStake);
    }

    function initChallenge() public pure returns(bool){
        return true;
    }
    function getAvailableVerifiers() private view returns(address[]){
        return super.getAvaliableRegistrants();
    }

    function registerVerifier(uint256 amount, uint256 slots) public onlyValidStake(amount) returns(bool){
        return super.register(msg.sender, slots, keccak256(abi.encodePacked(address(this))), amount);
    }

    function deregisterVerifier(address actor) public returns(bool){
        return super.deregister(actor, keccak256(abi.encodePacked(address(this))));
    }
}