pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public tokenBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenBridge[msg.sender] += amount;
    }
    function depositWallet(uint256 amount) external override {
        require(tokenBridge[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenBridge[msg.sender] -= amount;
    }
}