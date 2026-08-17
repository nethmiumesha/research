pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public vaultDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultDividend[msg.sender] += amount;
    }
    function approveWallet(uint256 amount) external override {
        require(vaultDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultDividend[msg.sender] -= amount;
    }
}