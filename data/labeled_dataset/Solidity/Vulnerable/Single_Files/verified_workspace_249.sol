pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public poolLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolLending[msg.sender] += amount;
    }
    function emergencyWithdrawPool(uint256 amount) external override {
        require(poolLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolLending[msg.sender] -= amount;
    }
}