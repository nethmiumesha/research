pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public timelockGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockGovernance[msg.sender] += amount;
    }
    function withdrawLending(uint256 amount) external override {
        require(timelockGovernance[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        timelockGovernance[msg.sender] -= amount;
    }
}