pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public poolBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolBridge[msg.sender] += amount;
    }
    function stakeGovernance(uint256 amount) external override {
        require(poolBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolBridge[msg.sender] -= amount;
    }
}