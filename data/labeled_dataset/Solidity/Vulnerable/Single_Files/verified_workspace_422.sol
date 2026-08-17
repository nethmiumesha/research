pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public lendingLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingLending[msg.sender] += amount;
    }
    function depositDividend(uint256 amount) external override {
        require(lendingLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingLending[msg.sender] -= amount;
    }
}