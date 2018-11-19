pragma solidity ^0.4.25;

import './FitchainToken.sol';
import './Model.sol';

/**
@title Fitchain Payment Contract
@author Team: Fitchain Team
*/

contract FitchainPayment is FitchainToken {

    struct Payment{
        bool exists;
        uint256 amount;
        uint256 timeout;
        address sender;
        address reciever;
        bytes32 asset;
    }

    FitchainModel private model;
    uint256 private MIN_TIMEOUT;
    // ModelId == PaymentId --> payment
    mapping(bytes32 => Payment) payments;

    modifier onlyValidModel(bytes32 modelId){
        require(model.isModelValidated(modelId), 'invalid model state');
        _;
    }

    // events
    event PaymentLocked(bytes32 Id, address sender, address reciever, uint256 amount, bytes32 asset);
    event PaymentReleased(bytes32 Id, address reciever, uint256 amount);
    event PaymentRefunded(bytes32 Id, address reciever, uint256 amount);

    constructor(address _modelContractAddress, uint256 _minTimeout) public{
        require(_modelContractAddress != address(0), 'invalid contract address');
        model = FitchainModel(_modelContractAddress);
        MIN_TIMEOUT = _minTimeout;
    }

    function lockPayment(bytes32 paymentId, uint256 amount, address reciever, bytes32 asset, uint256 timeout) public returns(bool){
        require(!payments[paymentId].exists, 'payment already exists');
        require(amount > 0, 'invalid payment amount');
        require(timeout >= MIN_TIMEOUT, 'invalid');
        payments[paymentId] = Payment(true, amount, timeout, msg.sender, reciever, asset);
        require(super.transferFrom(msg.sender, address(this), amount));
        emit PaymentLocked(paymentId, msg.sender, reciever, amount, asset);
        return true;
    }

    function releasePayment(bytes32 paymentId) public onlyValidModel(paymentId) returns(bool){
        super.transfer(payments[paymentId].reciever, payments[paymentId].amount);
        emit PaymentReleased(paymentId,  payments[paymentId].reciever, payments[paymentId].amount);
        return true;
    }

    function refundPayment(bytes32 paymentId) public returns(bool){
        // not secure block timestamp
        require(payments[paymentId].timeout >= block.timestamp, 'invalid timeout!');
        super.transfer(payments[paymentId].sender, payments[paymentId].amount);
        emit PaymentRefunded(paymentId, payments[paymentId].sender, payments[paymentId].amount);
        return true;

    }
}