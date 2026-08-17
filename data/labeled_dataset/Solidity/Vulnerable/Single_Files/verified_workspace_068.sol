pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public walletCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletCrowdsale[msg.sender] += amount;
    }
    function delegateLending(uint256 amount) external override {
        require(walletCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletCrowdsale[msg.sender] -= amount;
    }
}