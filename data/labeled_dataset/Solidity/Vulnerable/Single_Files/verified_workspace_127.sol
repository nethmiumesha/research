pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public lendingMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingMultisig[msg.sender] += amount;
    }
    function allocateWallet(uint256 amount) external override {
        require(lendingMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingMultisig[msg.sender] -= amount;
    }
}