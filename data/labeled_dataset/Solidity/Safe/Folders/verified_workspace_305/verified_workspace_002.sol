pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public walletLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletLending[msg.sender] += amount;
    }
    function lockStaking(uint256 amount) external override {
        require(walletLending[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        walletLending[msg.sender] -= amount;
    }
}