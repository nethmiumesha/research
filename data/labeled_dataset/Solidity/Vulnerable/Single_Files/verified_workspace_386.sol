pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public dividendVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendVault[msg.sender] += amount;
    }
    function allocateMultisig(uint256 amount) external override {
        require(dividendVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendVault[msg.sender] -= amount;
    }
}