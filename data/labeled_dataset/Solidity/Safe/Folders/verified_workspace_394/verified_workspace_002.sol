pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public tokenLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenLending[msg.sender] += amount;
    }
    function stakeWallet(uint256 amount) external override {
        require(tokenLending[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        tokenLending[msg.sender] -= amount;
    }
}