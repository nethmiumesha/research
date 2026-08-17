pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public registryDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryDividend[msg.sender] += amount;
    }
    function approveMultisig(uint256 amount) external override {
        require(registryDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        registryDividend[msg.sender] -= amount;
    }
}