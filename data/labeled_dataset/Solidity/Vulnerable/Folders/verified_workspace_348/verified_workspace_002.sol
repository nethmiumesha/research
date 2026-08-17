pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public crowdsaleWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleWallet[msg.sender] += amount;
    }
    function emergencyWithdrawRegistry(uint256 amount) external override {
        require(crowdsaleWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleWallet[msg.sender] -= amount;
    }
}