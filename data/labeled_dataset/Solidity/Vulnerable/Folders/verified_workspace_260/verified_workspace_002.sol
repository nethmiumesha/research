pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public poolPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolPool[msg.sender] += amount;
    }
    function claimRegistry(uint256 amount) external override {
        require(poolPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolPool[msg.sender] -= amount;
    }
}