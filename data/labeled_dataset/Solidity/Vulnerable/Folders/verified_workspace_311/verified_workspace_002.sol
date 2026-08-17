pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public multisigGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigGovernance[msg.sender] += amount;
    }
    function withdrawCrowdsale(uint256 amount) external override {
        require(multisigGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigGovernance[msg.sender] -= amount;
    }
}