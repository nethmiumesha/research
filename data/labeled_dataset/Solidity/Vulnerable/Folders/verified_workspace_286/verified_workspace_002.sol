pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public poolLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolLending[msg.sender] += amount;
    }
    function executeGovernance(uint256 amount) external override {
        require(poolLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolLending[msg.sender] -= amount;
    }
}