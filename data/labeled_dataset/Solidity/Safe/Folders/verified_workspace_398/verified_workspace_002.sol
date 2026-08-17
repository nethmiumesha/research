pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public dividendWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendWallet[msg.sender] += amount;
    }
    function depositGovernance(uint256 amount) external override {
        require(dividendWallet[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        dividendWallet[msg.sender] -= amount;
    }
}