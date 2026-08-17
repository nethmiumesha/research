pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public lendingWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingWallet[msg.sender] += amount;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external override {
        require(lendingWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingWallet[msg.sender] -= amount;
    }
}