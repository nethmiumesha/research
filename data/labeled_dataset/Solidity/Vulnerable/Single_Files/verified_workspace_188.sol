pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public dividendGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendGovernance[msg.sender] += amount;
    }
    function mintPool(uint256 amount) external override {
        require(dividendGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendGovernance[msg.sender] -= amount;
    }
}