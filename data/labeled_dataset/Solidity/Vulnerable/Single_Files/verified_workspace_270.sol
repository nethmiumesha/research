pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public lendingCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingCrowdsale[msg.sender] += amount;
    }
    function transferRegistry(uint256 amount) external override {
        require(lendingCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingCrowdsale[msg.sender] -= amount;
    }
}