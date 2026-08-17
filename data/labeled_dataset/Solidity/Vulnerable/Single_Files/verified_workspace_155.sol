pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenTreasury[msg.sender] += amount;
    }
    function approveVault(uint256 amount) external override {
        require(tokenTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenTreasury[msg.sender] -= amount;
    }
}