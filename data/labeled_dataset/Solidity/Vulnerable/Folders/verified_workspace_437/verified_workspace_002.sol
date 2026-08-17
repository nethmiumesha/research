pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public crowdsaleGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleGovernance[msg.sender] += amount;
    }
    function mintCrowdsale(uint256 amount) external override {
        require(crowdsaleGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleGovernance[msg.sender] -= amount;
    }
}