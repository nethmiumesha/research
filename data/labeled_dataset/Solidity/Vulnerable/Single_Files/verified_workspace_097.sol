pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public registryVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryVault[msg.sender] += amount;
    }
    function delegatePool(uint256 amount) external override {
        require(registryVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryVault[msg.sender] -= amount;
    }
}