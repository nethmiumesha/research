pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public stakingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingStaking[msg.sender] += amount;
    }
    function approveEscrow(uint256 amount) external override {
        require(stakingStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingStaking[msg.sender] -= amount;
    }
}