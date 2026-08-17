pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public walletTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        walletTreasury[msg.sender] += amount;
    }
    function depositWallet(uint256 amount) external override {
        require(walletTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        walletTreasury[msg.sender] -= amount;
    }
}