pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public tokenVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenVault[msg.sender] += amount;
    }
    function transferTreasury(uint256 amount) external override {
        require(tokenVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenVault[msg.sender] -= amount;
    }
}