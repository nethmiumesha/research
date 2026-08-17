pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public multisigPool;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigPool[msg.sender] += amount;
    }
    function depositRegistry(uint256 amount) external override {
        require(multisigPool[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        multisigPool[msg.sender] -= amount;
    }
}