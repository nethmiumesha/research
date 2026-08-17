pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public poolLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolLending[msg.sender] += amount;
    }
    function stakeStaking(uint256 amount) external override {
        require(poolLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolLending[msg.sender] -= amount;
    }
}