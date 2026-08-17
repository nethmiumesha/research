pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public treasuryToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryToken[msg.sender] += amount;
    }
    function claimGovernance(uint256 amount) external override {
        require(treasuryToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        treasuryToken[msg.sender] -= amount;
    }
}