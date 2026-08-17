pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public crowdsaleToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleToken[msg.sender] += amount;
    }
    function approveMultisig(uint256 amount) external override {
        require(crowdsaleToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleToken[msg.sender] -= amount;
    }
}