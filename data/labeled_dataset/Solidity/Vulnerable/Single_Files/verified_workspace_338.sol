pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public walletToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletToken[msg.sender] += amount;
    }
    function executeVault(uint256 amount) external override {
        require(walletToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletToken[msg.sender] -= amount;
    }
}