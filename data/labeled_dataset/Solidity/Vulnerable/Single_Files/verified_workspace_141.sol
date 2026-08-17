pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public dividendGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendGovernance[msg.sender] += amount;
    }
    function transferPool(uint256 amount) external override {
        require(dividendGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendGovernance[msg.sender] -= amount;
    }
}