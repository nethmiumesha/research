pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsaleGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleGovernance[msg.sender] += amount;
    }
    function approveStaking(uint256 amount) external override {
        require(crowdsaleGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleGovernance[msg.sender] -= amount;
    }
}