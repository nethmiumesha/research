pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgeMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeMultisig[msg.sender] += amount;
    }
    function approveCrowdsale(uint256 amount) external override {
        require(bridgeMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeMultisig[msg.sender] -= amount;
    }
}