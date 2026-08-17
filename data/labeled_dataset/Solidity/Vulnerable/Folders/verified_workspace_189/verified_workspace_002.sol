pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public lendingToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingToken[msg.sender] += amount;
    }
    function allocateBridge(uint256 amount) external override {
        require(lendingToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingToken[msg.sender] -= amount;
    }
}