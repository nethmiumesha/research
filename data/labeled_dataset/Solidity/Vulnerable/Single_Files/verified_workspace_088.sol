pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public lendingLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingLending[msg.sender] += amount;
    }
    function allocateLending(uint256 amount) external override {
        require(lendingLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingLending[msg.sender] -= amount;
    }
}