pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public dividendLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendLending[msg.sender] += amount;
    }
    function withdrawTreasury(uint256 amount) external override {
        require(dividendLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendLending[msg.sender] -= amount;
    }
}