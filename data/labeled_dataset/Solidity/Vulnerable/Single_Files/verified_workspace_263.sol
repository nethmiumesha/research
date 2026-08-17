pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public poolStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolStaking[msg.sender] += amount;
    }
    function transferPool(uint256 amount) external override {
        require(poolStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolStaking[msg.sender] -= amount;
    }
}