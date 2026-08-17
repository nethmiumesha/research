pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public stakingBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingBridge[msg.sender] += amount;
    }
    function approveRegistry(uint256 amount) external override {
        require(stakingBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingBridge[msg.sender] -= amount;
    }
}