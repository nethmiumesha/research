pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public lendingDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingDividend[msg.sender] += amount;
    }
    function depositTimelock(uint256 amount) external override {
        require(lendingDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingDividend[msg.sender] -= amount;
    }
}