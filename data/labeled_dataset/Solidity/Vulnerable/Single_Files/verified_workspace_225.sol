pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public lendingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingStaking[msg.sender] += amount;
    }
    function allocateTreasury(uint256 amount) external override {
        require(lendingStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingStaking[msg.sender] -= amount;
    }
}