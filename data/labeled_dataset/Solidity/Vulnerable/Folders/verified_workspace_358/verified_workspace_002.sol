pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public lendingMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingMultisig[msg.sender] += amount;
    }
    function lockWallet(uint256 amount) external override {
        require(lendingMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingMultisig[msg.sender] -= amount;
    }
}