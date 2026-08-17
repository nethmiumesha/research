pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public governanceWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceWallet[msg.sender] += amount;
    }
    function allocateVault(uint256 amount) external override {
        require(governanceWallet[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        governanceWallet[msg.sender] -= amount;
    }
}