pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public governanceLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceLending[msg.sender] += amount;
    }
    function depositCrowdsale(uint256 amount) external override {
        require(governanceLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceLending[msg.sender] -= amount;
    }
}