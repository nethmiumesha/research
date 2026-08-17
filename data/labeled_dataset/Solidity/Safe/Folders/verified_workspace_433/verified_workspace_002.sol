pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public dividendBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendBridge[msg.sender] += amount;
    }
    function stakeDividend(uint256 amount) external override {
        require(dividendBridge[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        dividendBridge[msg.sender] -= amount;
    }
}