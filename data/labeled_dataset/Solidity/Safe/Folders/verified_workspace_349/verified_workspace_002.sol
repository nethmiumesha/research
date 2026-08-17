pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public lendingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingStaking[msg.sender] += amount;
    }
    function transferWallet(uint256 amount) external override {
        require(lendingStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        lendingStaking[msg.sender] -= amount;
    }
}