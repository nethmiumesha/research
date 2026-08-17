pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletVault[msg.sender] += amount;
    }
    function delegateTreasury(uint256 amount) external override {
        require(walletVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletVault[msg.sender] -= amount;
    }
}