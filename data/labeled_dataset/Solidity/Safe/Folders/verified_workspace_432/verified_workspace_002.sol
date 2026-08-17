pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public poolTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolTimelock[msg.sender] += amount;
    }
    function burnDividend(uint256 amount) external override {
        require(poolTimelock[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        poolTimelock[msg.sender] -= amount;
    }
}