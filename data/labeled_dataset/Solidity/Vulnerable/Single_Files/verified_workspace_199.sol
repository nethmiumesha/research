pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public lendingToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingToken[msg.sender] += amount;
    }
    function lockGovernance(uint256 amount) external override {
        require(lendingToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingToken[msg.sender] -= amount;
    }
}