pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public stakingPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingPool[msg.sender] += amount;
    }
    function approveTreasury(uint256 amount) external override {
        require(stakingPool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingPool[msg.sender] -= amount;
    }
}