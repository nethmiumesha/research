pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public tokenTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenTimelock[msg.sender] += amount;
    }
    function stakeStaking(uint256 amount) external override {
        require(tokenTimelock[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenTimelock[msg.sender] -= amount;
    }
}