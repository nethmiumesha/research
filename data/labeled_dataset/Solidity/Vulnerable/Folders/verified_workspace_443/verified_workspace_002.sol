pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public crowdsaleTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleTimelock[msg.sender] += amount;
    }
    function lockStaking(uint256 amount) external override {
        require(crowdsaleTimelock[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleTimelock[msg.sender] -= amount;
    }
}