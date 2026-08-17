pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public registryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryCrowdsale[msg.sender] += amount;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external override {
        require(registryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        registryCrowdsale[msg.sender] -= amount;
    }
}