pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public multisigLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigLending[msg.sender] += amount;
    }
    function stakeRegistry(uint256 amount) external override {
        require(multisigLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigLending[msg.sender] -= amount;
    }
}