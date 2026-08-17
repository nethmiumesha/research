pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public walletEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletEscrow[msg.sender] += amount;
    }
    function transferWallet(uint256 amount) external override {
        require(walletEscrow[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletEscrow[msg.sender] -= amount;
    }
}