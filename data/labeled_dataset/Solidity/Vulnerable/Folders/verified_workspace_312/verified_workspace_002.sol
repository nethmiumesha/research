pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public tokenPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenPool[msg.sender] += amount;
    }
    function depositTreasury(uint256 amount) external override {
        require(tokenPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenPool[msg.sender] -= amount;
    }
}