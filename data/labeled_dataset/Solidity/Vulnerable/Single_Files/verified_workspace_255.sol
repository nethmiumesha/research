pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public escrowLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowLending[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(escrowLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowLending[msg.sender] -= amount;
    }
}