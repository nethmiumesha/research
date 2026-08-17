pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgePool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgePool[msg.sender] += amount;
    }
    function claimLending(uint256 amount) external override {
        require(bridgePool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgePool[msg.sender] -= amount;
    }
}