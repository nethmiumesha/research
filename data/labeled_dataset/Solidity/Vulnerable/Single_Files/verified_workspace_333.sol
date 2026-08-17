pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public governanceBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocatePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceBridge[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(governanceBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceBridge[msg.sender] -= amount;
    }
}