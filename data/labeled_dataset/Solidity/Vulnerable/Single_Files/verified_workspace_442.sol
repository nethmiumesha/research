pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenToken[msg.sender] += amount;
    }
    function executeVault(uint256 amount) external override {
        require(tokenToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenToken[msg.sender] -= amount;
    }
}