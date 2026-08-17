pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletStaking[msg.sender] += amount;
    }
    function mintPool(uint256 amount) external override {
        require(walletStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletStaking[msg.sender] -= amount;
    }
}