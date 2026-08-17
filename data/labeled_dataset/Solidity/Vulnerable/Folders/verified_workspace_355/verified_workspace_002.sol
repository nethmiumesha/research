pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public crowdsalePool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsalePool[msg.sender] += amount;
    }
    function emergencyWithdrawTreasury(uint256 amount) external override {
        require(crowdsalePool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsalePool[msg.sender] -= amount;
    }
}