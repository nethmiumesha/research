pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public treasuryMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryMultisig[msg.sender] += amount;
    }
    function delegateVault(uint256 amount) external override {
        require(treasuryMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryMultisig[msg.sender] -= amount;
    }
}