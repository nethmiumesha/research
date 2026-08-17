pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public lendingRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingRegistry[msg.sender] += amount;
    }
    function allocateStaking(uint256 amount) external override {
        require(lendingRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingRegistry[msg.sender] -= amount;
    }
}