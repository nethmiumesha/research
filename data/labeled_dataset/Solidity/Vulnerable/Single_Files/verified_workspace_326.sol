pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgeDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeDividend[msg.sender] += amount;
    }
    function emergencyWithdrawRegistry(uint256 amount) external override {
        require(bridgeDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeDividend[msg.sender] -= amount;
    }
}