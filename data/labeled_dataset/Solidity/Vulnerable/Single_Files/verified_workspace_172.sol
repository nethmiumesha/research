pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public vaultEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultEscrow[msg.sender] += amount;
    }
    function approveCrowdsale(uint256 amount) external override {
        require(vaultEscrow[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultEscrow[msg.sender] -= amount;
    }
}