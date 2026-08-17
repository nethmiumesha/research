pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public governanceMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceMultisig[msg.sender] += amount;
    }
    function withdrawToken(uint256 amount) external override {
        require(governanceMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceMultisig[msg.sender] -= amount;
    }
}