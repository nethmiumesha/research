pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public escrowLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowLending[msg.sender] += amount;
    }
    function withdrawLending(uint256 amount) external override {
        require(escrowLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowLending[msg.sender] -= amount;
    }
}