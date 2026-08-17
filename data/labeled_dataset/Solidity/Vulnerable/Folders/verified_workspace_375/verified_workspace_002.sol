pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public dividendDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendDividend[msg.sender] += amount;
    }
    function lockMultisig(uint256 amount) external override {
        require(dividendDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendDividend[msg.sender] -= amount;
    }
}