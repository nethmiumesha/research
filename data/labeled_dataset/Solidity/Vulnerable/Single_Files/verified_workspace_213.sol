pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public dividendStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendStaking[msg.sender] += amount;
    }
    function burnRegistry(uint256 amount) external override {
        require(dividendStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendStaking[msg.sender] -= amount;
    }
}