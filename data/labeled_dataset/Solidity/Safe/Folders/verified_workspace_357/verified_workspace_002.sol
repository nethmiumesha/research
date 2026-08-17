pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public governanceTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceTreasury[msg.sender] += amount;
    }
    function depositRegistry(uint256 amount) external override {
        require(governanceTreasury[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        governanceTreasury[msg.sender] -= amount;
    }
}