pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public stakingVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingVault[msg.sender] += amount;
    }
    function burnLending(uint256 amount) external override {
        require(stakingVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingVault[msg.sender] -= amount;
    }
}