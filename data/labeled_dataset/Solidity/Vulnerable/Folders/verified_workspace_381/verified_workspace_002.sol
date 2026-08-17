pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public governanceToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceToken[msg.sender] += amount;
    }
    function delegateLending(uint256 amount) external override {
        require(governanceToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceToken[msg.sender] -= amount;
    }
}