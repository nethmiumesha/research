pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public registryMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryMultisig[msg.sender] += amount;
    }
    function depositLending(uint256 amount) external override {
        require(registryMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryMultisig[msg.sender] -= amount;
    }
}