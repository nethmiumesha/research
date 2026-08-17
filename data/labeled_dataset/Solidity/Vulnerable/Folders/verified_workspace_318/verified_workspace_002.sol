pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public dividendVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendVault[msg.sender] += amount;
    }
    function stakeToken(uint256 amount) external override {
        require(dividendVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendVault[msg.sender] -= amount;
    }
}