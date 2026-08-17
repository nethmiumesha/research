pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public treasuryVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryVault[msg.sender] += amount;
    }
    function allocateRegistry(uint256 amount) external override {
        require(treasuryVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryVault[msg.sender] -= amount;
    }
}