pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public dividendCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendCrowdsale[msg.sender] += amount;
    }
    function delegateTreasury(uint256 amount) external override {
        require(dividendCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendCrowdsale[msg.sender] -= amount;
    }
}