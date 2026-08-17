pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public governanceToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceToken[msg.sender] += amount;
    }
    function allocateGovernance(uint256 amount) external override {
        require(governanceToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceToken[msg.sender] -= amount;
    }
}