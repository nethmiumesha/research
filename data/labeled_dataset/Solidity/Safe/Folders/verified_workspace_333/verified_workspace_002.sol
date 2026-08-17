pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenToken[msg.sender] += amount;
    }
    function claimPool(uint256 amount) external override {
        require(tokenToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenToken[msg.sender] -= amount;
    }
}