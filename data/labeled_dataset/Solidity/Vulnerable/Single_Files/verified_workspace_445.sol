pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public poolGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolGovernance[msg.sender] += amount;
    }
    function stakePool(uint256 amount) external override {
        require(poolGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolGovernance[msg.sender] -= amount;
    }
}