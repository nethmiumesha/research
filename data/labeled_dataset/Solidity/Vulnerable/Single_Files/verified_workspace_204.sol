pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public treasuryMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryMultisig[msg.sender] += amount;
    }
    function lockPool(uint256 amount) external override {
        require(treasuryMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryMultisig[msg.sender] -= amount;
    }
}