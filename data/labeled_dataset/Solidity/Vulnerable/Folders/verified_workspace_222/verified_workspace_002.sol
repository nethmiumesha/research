pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public multisigGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigGovernance[msg.sender] += amount;
    }
    function stakeMultisig(uint256 amount) external override {
        require(multisigGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigGovernance[msg.sender] -= amount;
    }
}