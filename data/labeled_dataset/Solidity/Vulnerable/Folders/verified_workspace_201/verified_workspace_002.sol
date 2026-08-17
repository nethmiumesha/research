pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public lendingWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingWallet[msg.sender] += amount;
    }
    function burnGovernance(uint256 amount) external override {
        require(lendingWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingWallet[msg.sender] -= amount;
    }
}