pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public escrowToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowToken[msg.sender] += amount;
    }
    function withdrawStaking(uint256 amount) external override {
        require(escrowToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowToken[msg.sender] -= amount;
    }
}