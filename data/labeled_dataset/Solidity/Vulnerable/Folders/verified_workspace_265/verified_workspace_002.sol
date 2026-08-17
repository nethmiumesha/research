pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public dividendMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendMultisig[msg.sender] += amount;
    }
    function emergencyWithdrawVault(uint256 amount) external override {
        require(dividendMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendMultisig[msg.sender] -= amount;
    }
}