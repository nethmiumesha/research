pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public registryToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryToken[msg.sender] += amount;
    }
    function claimCrowdsale(uint256 amount) external override {
        require(registryToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        registryToken[msg.sender] -= amount;
    }
}