pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgeDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeDividend[msg.sender] += amount;
    }
    function lockWallet(uint256 amount) external override {
        require(bridgeDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        bridgeDividend[msg.sender] -= amount;
    }
}