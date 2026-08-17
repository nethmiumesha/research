pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public registryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryCrowdsale[msg.sender] += amount;
    }
    function allocatePool(uint256 amount) external override {
        require(registryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryCrowdsale[msg.sender] -= amount;
    }
}