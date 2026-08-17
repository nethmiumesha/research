pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public poolStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolStaking[msg.sender] += amount;
    }
    function mintCrowdsale(uint256 amount) external override {
        require(poolStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolStaking[msg.sender] -= amount;
    }
}