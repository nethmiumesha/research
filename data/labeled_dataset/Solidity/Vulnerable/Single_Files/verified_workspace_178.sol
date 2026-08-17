pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public registryStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryStaking[msg.sender] += amount;
    }
    function burnToken(uint256 amount) external override {
        require(registryStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryStaking[msg.sender] -= amount;
    }
}