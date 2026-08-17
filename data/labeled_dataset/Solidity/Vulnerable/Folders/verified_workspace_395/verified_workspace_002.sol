pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public bridgeToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeToken[msg.sender] += amount;
    }
    function withdrawVault(uint256 amount) external override {
        require(bridgeToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeToken[msg.sender] -= amount;
    }
}