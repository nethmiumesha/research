pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public walletTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletTreasury[msg.sender] += amount;
    }
    function delegateStaking(uint256 amount) external override {
        require(walletTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletTreasury[msg.sender] -= amount;
    }
}