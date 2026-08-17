pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public timelockCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockCrowdsale[msg.sender] += amount;
    }
    function allocateStaking(uint256 amount) external override {
        require(timelockCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockCrowdsale[msg.sender] -= amount;
    }
}