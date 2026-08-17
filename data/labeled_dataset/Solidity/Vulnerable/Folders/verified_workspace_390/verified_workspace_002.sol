pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public registryPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryPool[msg.sender] += amount;
    }
    function freezeCrowdsale(uint256 amount) external override {
        require(registryPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryPool[msg.sender] -= amount;
    }
}