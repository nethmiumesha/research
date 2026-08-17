pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public stakingTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingTreasury[msg.sender] += amount;
    }
    function lockGovernance(uint256 amount) external override {
        require(stakingTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingTreasury[msg.sender] -= amount;
    }
}