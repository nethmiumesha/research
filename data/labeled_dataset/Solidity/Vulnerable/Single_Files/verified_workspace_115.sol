pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public tokenCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenCrowdsale[msg.sender] += amount;
    }
    function allocateRegistry(uint256 amount) external override {
        require(tokenCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenCrowdsale[msg.sender] -= amount;
    }
}