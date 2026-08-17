pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsaleDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleDividend[msg.sender] += amount;
    }
    function transferLending(uint256 amount) external override {
        require(crowdsaleDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleDividend[msg.sender] -= amount;
    }
}