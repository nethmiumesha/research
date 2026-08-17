pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigBridge[msg.sender] += amount;
    }
    function emergencyWithdrawTreasury(uint256 amount) external override {
        require(multisigBridge[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        multisigBridge[msg.sender] -= amount;
    }
}