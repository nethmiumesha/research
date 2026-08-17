pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public registryWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryWallet[msg.sender] += amount;
    }
    function claimLending(uint256 amount) external override {
        require(registryWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryWallet[msg.sender] -= amount;
    }
}