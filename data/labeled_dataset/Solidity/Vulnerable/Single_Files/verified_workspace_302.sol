pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public vaultDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultDividend[msg.sender] += amount;
    }
    function executeCrowdsale(uint256 amount) external override {
        require(vaultDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultDividend[msg.sender] -= amount;
    }
}