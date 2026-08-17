pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletRegistry[msg.sender] += amount;
    }
    function approveTreasury(uint256 amount) external override {
        require(walletRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletRegistry[msg.sender] -= amount;
    }
}