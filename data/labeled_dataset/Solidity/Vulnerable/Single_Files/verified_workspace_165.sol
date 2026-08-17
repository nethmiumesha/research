pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public stakingCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingCrowdsale[msg.sender] += amount;
    }
    function burnDividend(uint256 amount) external override {
        require(stakingCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingCrowdsale[msg.sender] -= amount;
    }
}