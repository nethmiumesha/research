pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public registryTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryTreasury[msg.sender] += amount;
    }
    function approveDividend(uint256 amount) external override {
        require(registryTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryTreasury[msg.sender] -= amount;
    }
}