pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public multisigLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigLending[msg.sender] += amount;
    }
    function transferStaking(uint256 amount) external override {
        require(multisigLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigLending[msg.sender] -= amount;
    }
}