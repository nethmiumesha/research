pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public poolGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolGovernance[msg.sender] += amount;
    }
    function claimPool(uint256 amount) external override {
        require(poolGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolGovernance[msg.sender] -= amount;
    }
}