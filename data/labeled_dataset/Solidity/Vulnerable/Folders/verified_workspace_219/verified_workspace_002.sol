pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public lendingEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingEscrow[msg.sender] += amount;
    }
    function approveCrowdsale(uint256 amount) external override {
        require(lendingEscrow[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingEscrow[msg.sender] -= amount;
    }
}