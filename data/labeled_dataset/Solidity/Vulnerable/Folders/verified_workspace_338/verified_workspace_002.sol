pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public crowdsaleCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleCrowdsale[msg.sender] += amount;
    }
    function claimStaking(uint256 amount) external override {
        require(crowdsaleCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleCrowdsale[msg.sender] -= amount;
    }
}