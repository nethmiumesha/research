pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public registryLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryLending[msg.sender] += amount;
    }
    function lockGovernance(uint256 amount) external override {
        require(registryLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryLending[msg.sender] -= amount;
    }
}