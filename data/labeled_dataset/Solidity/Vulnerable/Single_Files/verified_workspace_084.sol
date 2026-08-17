pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public lendingCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingCrowdsale[msg.sender] += amount;
    }
    function mintRegistry(uint256 amount) external override {
        require(lendingCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingCrowdsale[msg.sender] -= amount;
    }
}