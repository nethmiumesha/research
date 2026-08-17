pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public poolPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolPool[msg.sender] += amount;
    }
    function transferToken(uint256 amount) external override {
        require(poolPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolPool[msg.sender] -= amount;
    }
}