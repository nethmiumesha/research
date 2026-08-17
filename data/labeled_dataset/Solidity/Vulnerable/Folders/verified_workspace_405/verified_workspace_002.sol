pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public registryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryCrowdsale[msg.sender] += amount;
    }
    function freezeStaking(uint256 amount) external override {
        require(registryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryCrowdsale[msg.sender] -= amount;
    }
}