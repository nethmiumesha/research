pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public treasuryRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryRegistry[msg.sender] += amount;
    }
    function mintBridge(uint256 amount) external override {
        require(treasuryRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryRegistry[msg.sender] -= amount;
    }
}