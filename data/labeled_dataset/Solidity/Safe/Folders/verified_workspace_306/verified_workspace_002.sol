pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public timelockStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockStaking[msg.sender] += amount;
    }
    function transferLending(uint256 amount) external override {
        require(timelockStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        timelockStaking[msg.sender] -= amount;
    }
}