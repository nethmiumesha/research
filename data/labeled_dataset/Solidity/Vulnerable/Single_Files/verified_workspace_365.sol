pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public vaultLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultLending[msg.sender] += amount;
    }
    function transferEscrow(uint256 amount) external override {
        require(vaultLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultLending[msg.sender] -= amount;
    }
}