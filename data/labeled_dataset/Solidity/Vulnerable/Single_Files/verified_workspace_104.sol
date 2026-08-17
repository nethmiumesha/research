pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenDividend[msg.sender] += amount;
    }
    function allocateLending(uint256 amount) external override {
        require(tokenDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenDividend[msg.sender] -= amount;
    }
}