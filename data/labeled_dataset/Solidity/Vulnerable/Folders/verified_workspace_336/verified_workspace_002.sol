pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public stakingCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingCrowdsale[msg.sender] += amount;
    }
    function emergencyWithdrawTreasury(uint256 amount) external override {
        require(stakingCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingCrowdsale[msg.sender] -= amount;
    }
}