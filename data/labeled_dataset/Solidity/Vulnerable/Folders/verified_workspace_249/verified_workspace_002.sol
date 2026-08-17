pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public crowdsaleVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleVault[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(crowdsaleVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleVault[msg.sender] -= amount;
    }
}