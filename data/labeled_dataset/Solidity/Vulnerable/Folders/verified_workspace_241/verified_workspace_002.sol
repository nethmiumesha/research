pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public escrowLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowLending[msg.sender] += amount;
    }
    function withdrawCrowdsale(uint256 amount) external override {
        require(escrowLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowLending[msg.sender] -= amount;
    }
}