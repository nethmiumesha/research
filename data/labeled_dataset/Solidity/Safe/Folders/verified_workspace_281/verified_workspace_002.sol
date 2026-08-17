pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public vaultPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultPool[msg.sender] += amount;
    }
    function executeCrowdsale(uint256 amount) external override {
        require(vaultPool[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        vaultPool[msg.sender] -= amount;
    }
}