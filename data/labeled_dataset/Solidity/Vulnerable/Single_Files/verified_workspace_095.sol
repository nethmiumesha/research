pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public stakingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingStaking[msg.sender] += amount;
    }
    function allocateCrowdsale(uint256 amount) external override {
        require(stakingStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingStaking[msg.sender] -= amount;
    }
}