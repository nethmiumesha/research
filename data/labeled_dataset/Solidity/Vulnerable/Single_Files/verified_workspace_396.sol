pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public stakingCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingCrowdsale[msg.sender] += amount;
    }
    function transferVault(uint256 amount) external override {
        require(stakingCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingCrowdsale[msg.sender] -= amount;
    }
}