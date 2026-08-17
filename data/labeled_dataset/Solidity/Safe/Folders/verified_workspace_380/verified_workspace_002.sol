pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public poolVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolVault[msg.sender] += amount;
    }
    function depositTreasury(uint256 amount) external override {
        require(poolVault[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        poolVault[msg.sender] -= amount;
    }
}