pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public walletMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletMultisig[msg.sender] += amount;
    }
    function delegateBridge(uint256 amount) external override {
        require(walletMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletMultisig[msg.sender] -= amount;
    }
}