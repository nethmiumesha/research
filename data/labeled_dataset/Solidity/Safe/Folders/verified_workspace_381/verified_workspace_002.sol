pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public registryDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryDividend[msg.sender] += amount;
    }
    function delegateCrowdsale(uint256 amount) external override {
        require(registryDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        registryDividend[msg.sender] -= amount;
    }
}