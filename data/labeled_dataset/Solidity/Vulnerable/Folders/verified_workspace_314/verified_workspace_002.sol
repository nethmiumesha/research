pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgeTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeTreasury[msg.sender] += amount;
    }
    function withdrawGovernance(uint256 amount) external override {
        require(bridgeTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeTreasury[msg.sender] -= amount;
    }
}