pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public bridgeLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeLending[msg.sender] += amount;
    }
    function delegateTreasury(uint256 amount) external override {
        require(bridgeLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeLending[msg.sender] -= amount;
    }
}