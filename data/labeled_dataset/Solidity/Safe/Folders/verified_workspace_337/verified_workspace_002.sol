pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgePool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgePool[msg.sender] += amount;
    }
    function burnLending(uint256 amount) external override {
        require(bridgePool[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        bridgePool[msg.sender] -= amount;
    }
}