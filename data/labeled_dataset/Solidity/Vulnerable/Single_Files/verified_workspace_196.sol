pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public treasuryPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryPool[msg.sender] += amount;
    }
    function claimStaking(uint256 amount) external override {
        require(treasuryPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryPool[msg.sender] -= amount;
    }
}