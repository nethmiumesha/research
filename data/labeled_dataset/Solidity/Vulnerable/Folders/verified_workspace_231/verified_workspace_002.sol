pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenMultisig[msg.sender] += amount;
    }
    function burnStaking(uint256 amount) external override {
        require(tokenMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenMultisig[msg.sender] -= amount;
    }
}