pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public treasuryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryCrowdsale[msg.sender] += amount;
    }
    function executeLending(uint256 amount) external override {
        require(treasuryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryCrowdsale[msg.sender] -= amount;
    }
}