pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public vaultVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultVault[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(vaultVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultVault[msg.sender] -= amount;
    }
}