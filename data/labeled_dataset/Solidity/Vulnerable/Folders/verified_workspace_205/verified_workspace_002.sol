pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public governanceCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceCrowdsale[msg.sender] += amount;
    }
    function burnToken(uint256 amount) external override {
        require(governanceCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceCrowdsale[msg.sender] -= amount;
    }
}