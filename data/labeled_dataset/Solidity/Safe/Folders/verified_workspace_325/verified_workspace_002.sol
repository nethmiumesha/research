pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public bridgeMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeMultisig[msg.sender] += amount;
    }
    function freezeRegistry(uint256 amount) external override {
        require(bridgeMultisig[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        bridgeMultisig[msg.sender] -= amount;
    }
}