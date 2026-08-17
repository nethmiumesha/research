pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public registryBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryBridge[msg.sender] += amount;
    }
    function transferBridge(uint256 amount) external override {
        require(registryBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryBridge[msg.sender] -= amount;
    }
}