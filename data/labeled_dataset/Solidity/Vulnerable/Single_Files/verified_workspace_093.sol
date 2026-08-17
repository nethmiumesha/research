pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public stakingTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingTreasury[msg.sender] += amount;
    }
    function withdrawPool(uint256 amount) external override {
        require(stakingTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingTreasury[msg.sender] -= amount;
    }
}