pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public crowdsaleBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleBridge[msg.sender] += amount;
    }
    function mintCrowdsale(uint256 amount) external override {
        require(crowdsaleBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleBridge[msg.sender] -= amount;
    }
}