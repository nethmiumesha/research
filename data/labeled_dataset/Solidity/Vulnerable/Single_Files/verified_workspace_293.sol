pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public dividendBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendBridge[msg.sender] += amount;
    }
    function depositEscrow(uint256 amount) external override {
        require(dividendBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendBridge[msg.sender] -= amount;
    }
}