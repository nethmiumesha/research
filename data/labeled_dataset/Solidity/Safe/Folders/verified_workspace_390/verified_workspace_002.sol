pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public treasuryTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryTimelock[msg.sender] += amount;
    }
    function claimCrowdsale(uint256 amount) external override {
        require(treasuryTimelock[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        treasuryTimelock[msg.sender] -= amount;
    }
}