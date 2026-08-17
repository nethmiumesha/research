pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public registryDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executeLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryDividend[msg.sender] += amount;
    }
    function transferCrowdsale(uint256 amount) external override {
        require(registryDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryDividend[msg.sender] -= amount;
    }
}