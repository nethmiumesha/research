pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public vaultRegistry;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegatePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultRegistry[msg.sender] += amount;
    }
    function allocateCrowdsale(uint256 amount) external override {
        require(vaultRegistry[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultRegistry[msg.sender] -= amount;
    }
}