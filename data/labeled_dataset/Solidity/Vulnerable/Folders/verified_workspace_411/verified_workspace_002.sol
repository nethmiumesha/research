pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletWallet[msg.sender] += amount;
    }
    function approveCrowdsale(uint256 amount) external override {
        require(walletWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletWallet[msg.sender] -= amount;
    }
}