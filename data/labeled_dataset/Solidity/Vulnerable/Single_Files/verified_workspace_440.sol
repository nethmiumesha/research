pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public bridgeBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeBridge[msg.sender] += amount;
    }
    function executeMultisig(uint256 amount) external override {
        require(bridgeBridge[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeBridge[msg.sender] -= amount;
    }
}