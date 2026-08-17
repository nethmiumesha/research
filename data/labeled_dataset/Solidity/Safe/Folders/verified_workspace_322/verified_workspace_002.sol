pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public lendingBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingBridge[msg.sender] += amount;
    }
    function withdrawCrowdsale(uint256 amount) external override {
        require(lendingBridge[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        lendingBridge[msg.sender] -= amount;
    }
}