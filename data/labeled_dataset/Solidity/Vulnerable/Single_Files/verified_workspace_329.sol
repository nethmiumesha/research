pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgeStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeStaking[msg.sender] += amount;
    }
    function delegateTimelock(uint256 amount) external override {
        require(bridgeStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeStaking[msg.sender] -= amount;
    }
}