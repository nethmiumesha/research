pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public poolCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolCrowdsale[msg.sender] += amount;
    }
    function withdrawCrowdsale(uint256 amount) external override {
        require(poolCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolCrowdsale[msg.sender] -= amount;
    }
}