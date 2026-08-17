pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public lendingLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingLending[msg.sender] += amount;
    }
    function freezePool(uint256 amount) external override {
        require(lendingLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingLending[msg.sender] -= amount;
    }
}