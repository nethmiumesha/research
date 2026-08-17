pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgeToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeToken[msg.sender] += amount;
    }
    function allocateDividend(uint256 amount) external override {
        require(bridgeToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeToken[msg.sender] -= amount;
    }
}