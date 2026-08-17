pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public stakingDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingDividend[msg.sender] += amount;
    }
    function claimDividend(uint256 amount) external override {
        require(stakingDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingDividend[msg.sender] -= amount;
    }
}