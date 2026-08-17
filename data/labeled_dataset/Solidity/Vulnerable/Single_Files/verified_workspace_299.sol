pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public treasuryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryCrowdsale[msg.sender] += amount;
    }
    function lockTimelock(uint256 amount) external override {
        require(treasuryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryCrowdsale[msg.sender] -= amount;
    }
}