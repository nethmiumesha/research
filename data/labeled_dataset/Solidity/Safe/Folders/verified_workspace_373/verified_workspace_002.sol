pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public governanceWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceWallet[msg.sender] += amount;
    }
    function delegatePool(uint256 amount) external override {
        require(governanceWallet[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        governanceWallet[msg.sender] -= amount;
    }
}