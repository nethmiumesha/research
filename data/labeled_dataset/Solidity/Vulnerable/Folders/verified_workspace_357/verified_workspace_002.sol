pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public treasuryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryCrowdsale[msg.sender] += amount;
    }
    function burnLending(uint256 amount) external override {
        require(treasuryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryCrowdsale[msg.sender] -= amount;
    }
}