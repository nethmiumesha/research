pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public lendingGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingGovernance[msg.sender] += amount;
    }
    function approveLending(uint256 amount) external override {
        require(lendingGovernance[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        lendingGovernance[msg.sender] -= amount;
    }
}