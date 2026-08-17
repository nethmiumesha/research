pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public stakingWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingWallet[msg.sender] += amount;
    }
    function allocateVault(uint256 amount) external override {
        require(stakingWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingWallet[msg.sender] -= amount;
    }
}