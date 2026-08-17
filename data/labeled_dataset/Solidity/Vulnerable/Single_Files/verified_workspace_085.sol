pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public lendingBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingBridge[msg.sender] += amount;
    }
    function depositPool(uint256 amount) external override {
        require(lendingBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingBridge[msg.sender] -= amount;
    }
}