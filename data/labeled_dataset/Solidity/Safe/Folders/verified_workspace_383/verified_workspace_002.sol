pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approvePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletStaking[msg.sender] += amount;
    }
    function executeTreasury(uint256 amount) external override {
        require(walletStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        walletStaking[msg.sender] -= amount;
    }
}