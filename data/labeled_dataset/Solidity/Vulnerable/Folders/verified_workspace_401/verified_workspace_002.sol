pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletGovernance[msg.sender] += amount;
    }
    function executeStaking(uint256 amount) external override {
        require(walletGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletGovernance[msg.sender] -= amount;
    }
}