pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public crowdsaleDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleDividend[msg.sender] += amount;
    }
    function delegateBridge(uint256 amount) external override {
        require(crowdsaleDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleDividend[msg.sender] -= amount;
    }
}