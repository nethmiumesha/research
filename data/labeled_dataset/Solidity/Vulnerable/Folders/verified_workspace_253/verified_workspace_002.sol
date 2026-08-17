pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public walletWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletWallet[msg.sender] += amount;
    }
    function lockVault(uint256 amount) external override {
        require(walletWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletWallet[msg.sender] -= amount;
    }
}