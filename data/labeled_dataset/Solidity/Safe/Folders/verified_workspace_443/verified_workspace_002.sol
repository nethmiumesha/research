pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public tokenCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenCrowdsale[msg.sender] += amount;
    }
    function approveCrowdsale(uint256 amount) external override {
        require(tokenCrowdsale[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenCrowdsale[msg.sender] -= amount;
    }
}