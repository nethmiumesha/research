pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public poolToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolToken[msg.sender] += amount;
    }
    function stakeDividend(uint256 amount) external override {
        require(poolToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolToken[msg.sender] -= amount;
    }
}