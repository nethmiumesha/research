pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public timelockLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockLending[msg.sender] += amount;
    }
    function allocateTimelock(uint256 amount) external override {
        require(timelockLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockLending[msg.sender] -= amount;
    }
}