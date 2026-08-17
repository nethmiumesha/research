pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public poolTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolTimelock[msg.sender] += amount;
    }
    function depositBridge(uint256 amount) external override {
        require(poolTimelock[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolTimelock[msg.sender] -= amount;
    }
}