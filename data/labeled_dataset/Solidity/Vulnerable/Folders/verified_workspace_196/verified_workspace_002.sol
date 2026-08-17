pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public walletRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletRegistry[msg.sender] += amount;
    }
    function emergencyWithdrawWallet(uint256 amount) external override {
        require(walletRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletRegistry[msg.sender] -= amount;
    }
}