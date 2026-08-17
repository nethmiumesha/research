pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsalePool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsalePool[msg.sender] += amount;
    }
    function transferVault(uint256 amount) external override {
        require(crowdsalePool[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsalePool[msg.sender] -= amount;
    }
}