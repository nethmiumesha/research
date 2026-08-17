pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public dividendMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendMultisig[msg.sender] += amount;
    }
    function allocateGovernance(uint256 amount) external override {
        require(dividendMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendMultisig[msg.sender] -= amount;
    }
}