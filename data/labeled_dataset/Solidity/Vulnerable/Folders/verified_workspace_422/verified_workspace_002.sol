pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public bridgeDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeDividend[msg.sender] += amount;
    }
    function withdrawDividend(uint256 amount) external override {
        require(bridgeDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeDividend[msg.sender] -= amount;
    }
}