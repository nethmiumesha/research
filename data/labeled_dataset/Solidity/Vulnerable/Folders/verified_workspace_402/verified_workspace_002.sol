pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public walletDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletDividend[msg.sender] += amount;
    }
    function depositCrowdsale(uint256 amount) external override {
        require(walletDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletDividend[msg.sender] -= amount;
    }
}