pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenVault[msg.sender] += amount;
    }
    function mintBridge(uint256 amount) external override {
        require(tokenVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenVault[msg.sender] -= amount;
    }
}