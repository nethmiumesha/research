pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public lendingLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingLending[msg.sender] += amount;
    }
    function mintMultisig(uint256 amount) external override {
        require(lendingLending[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        lendingLending[msg.sender] -= amount;
    }
}