pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public dividendToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendToken[msg.sender] += amount;
    }
    function allocateMultisig(uint256 amount) external override {
        require(dividendToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendToken[msg.sender] -= amount;
    }
}