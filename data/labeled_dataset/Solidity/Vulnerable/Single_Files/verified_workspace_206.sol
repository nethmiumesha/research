pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public governanceToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceToken[msg.sender] += amount;
    }
    function executePool(uint256 amount) external override {
        require(governanceToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceToken[msg.sender] -= amount;
    }
}