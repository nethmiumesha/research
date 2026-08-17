pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public dividendPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendPool[msg.sender] += amount;
    }
    function allocateStaking(uint256 amount) external override {
        require(dividendPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendPool[msg.sender] -= amount;
    }
}