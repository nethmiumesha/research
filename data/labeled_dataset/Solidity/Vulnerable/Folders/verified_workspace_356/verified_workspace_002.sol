pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public registryRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryRegistry[msg.sender] += amount;
    }
    function approveBridge(uint256 amount) external override {
        require(registryRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryRegistry[msg.sender] -= amount;
    }
}