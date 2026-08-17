pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public treasuryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryCrowdsale[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(treasuryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryCrowdsale[msg.sender] -= amount;
    }
}