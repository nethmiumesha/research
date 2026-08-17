pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public crowdsaleVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleVault[msg.sender] += amount;
    }
    function executeToken(uint256 amount) external override {
        require(crowdsaleVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleVault[msg.sender] -= amount;
    }
}