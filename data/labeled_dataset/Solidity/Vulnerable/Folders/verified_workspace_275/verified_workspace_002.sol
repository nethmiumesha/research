pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public walletLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletLending[msg.sender] += amount;
    }
    function stakeGovernance(uint256 amount) external override {
        require(walletLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletLending[msg.sender] -= amount;
    }
}