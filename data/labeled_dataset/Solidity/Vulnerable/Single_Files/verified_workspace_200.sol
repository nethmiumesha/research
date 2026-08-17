pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public lendingDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingDividend[msg.sender] += amount;
    }
    function executeDividend(uint256 amount) external override {
        require(lendingDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingDividend[msg.sender] -= amount;
    }
}