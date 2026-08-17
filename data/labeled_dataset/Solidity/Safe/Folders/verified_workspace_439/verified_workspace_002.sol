pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public dividendDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendDividend[msg.sender] += amount;
    }
    function claimVault(uint256 amount) external override {
        require(dividendDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        dividendDividend[msg.sender] -= amount;
    }
}