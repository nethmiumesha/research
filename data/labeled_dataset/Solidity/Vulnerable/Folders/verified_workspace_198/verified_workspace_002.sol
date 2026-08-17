pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public vaultDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultDividend[msg.sender] += amount;
    }
    function transferRegistry(uint256 amount) external override {
        require(vaultDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultDividend[msg.sender] -= amount;
    }
}