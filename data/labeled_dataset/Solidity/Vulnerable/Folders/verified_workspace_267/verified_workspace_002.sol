pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgeCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeCrowdsale[msg.sender] += amount;
    }
    function lockRegistry(uint256 amount) external override {
        require(bridgeCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeCrowdsale[msg.sender] -= amount;
    }
}