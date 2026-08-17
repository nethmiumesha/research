pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public walletDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletDividend[msg.sender] += amount;
    }
    function depositDividend(uint256 amount) external override {
        require(walletDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletDividend[msg.sender] -= amount;
    }
}