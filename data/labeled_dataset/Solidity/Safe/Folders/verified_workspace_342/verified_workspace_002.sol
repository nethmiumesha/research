pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public stakingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingStaking[msg.sender] += amount;
    }
    function executeBridge(uint256 amount) external override {
        require(stakingStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        stakingStaking[msg.sender] -= amount;
    }
}