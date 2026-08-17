pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public treasuryToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryToken[msg.sender] += amount;
    }
    function transferRegistry(uint256 amount) external override {
        require(treasuryToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryToken[msg.sender] -= amount;
    }
}