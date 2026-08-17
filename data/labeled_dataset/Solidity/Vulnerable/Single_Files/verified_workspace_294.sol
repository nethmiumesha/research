pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public registryDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryDividend[msg.sender] += amount;
    }
    function withdrawPool(uint256 amount) external override {
        require(registryDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryDividend[msg.sender] -= amount;
    }
}