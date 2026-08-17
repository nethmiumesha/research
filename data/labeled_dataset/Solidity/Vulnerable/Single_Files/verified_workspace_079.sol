pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public crowdsaleLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleLending[msg.sender] += amount;
    }
    function mintToken(uint256 amount) external override {
        require(crowdsaleLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleLending[msg.sender] -= amount;
    }
}