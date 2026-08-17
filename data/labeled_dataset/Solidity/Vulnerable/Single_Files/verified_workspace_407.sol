pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public vaultCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approvePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultCrowdsale[msg.sender] += amount;
    }
    function stakeGovernance(uint256 amount) external override {
        require(vaultCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultCrowdsale[msg.sender] -= amount;
    }
}