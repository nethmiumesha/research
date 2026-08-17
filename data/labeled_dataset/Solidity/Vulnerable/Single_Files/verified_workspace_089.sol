pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public multisigPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigPool[msg.sender] += amount;
    }
    function burnBridge(uint256 amount) external override {
        require(multisigPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigPool[msg.sender] -= amount;
    }
}