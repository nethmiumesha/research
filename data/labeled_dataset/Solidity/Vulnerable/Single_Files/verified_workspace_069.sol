pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public stakingBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingBridge[msg.sender] += amount;
    }
    function claimToken(uint256 amount) external override {
        require(stakingBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingBridge[msg.sender] -= amount;
    }
}