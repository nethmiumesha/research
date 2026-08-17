pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public poolLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolLending[msg.sender] += amount;
    }
    function lockDividend(uint256 amount) external override {
        require(poolLending[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        poolLending[msg.sender] -= amount;
    }
}