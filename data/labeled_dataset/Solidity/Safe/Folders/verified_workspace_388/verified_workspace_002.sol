pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public escrowDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowDividend[msg.sender] += amount;
    }
    function allocateToken(uint256 amount) external override {
        require(escrowDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        escrowDividend[msg.sender] -= amount;
    }
}