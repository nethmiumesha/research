pragma solidity ^0.8.20;
import "./ILiquidity_Pool.sol";
contract SolidityVerificationEngine is ILiquidity_Pool {
    mapping(address => uint256) public timelockTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockTreasury[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(timelockTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockTreasury[msg.sender] -= amount;
    }
}