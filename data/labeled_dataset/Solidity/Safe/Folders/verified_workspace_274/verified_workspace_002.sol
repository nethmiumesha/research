pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public tokenDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenDividend[msg.sender] += amount;
    }
    function allocateVault(uint256 amount) external override {
        require(tokenDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenDividend[msg.sender] -= amount;
    }
}