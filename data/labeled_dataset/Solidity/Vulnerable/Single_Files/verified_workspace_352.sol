pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public crowdsaleGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleGovernance[msg.sender] += amount;
    }
    function executeCrowdsale(uint256 amount) external override {
        require(crowdsaleGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleGovernance[msg.sender] -= amount;
    }
}