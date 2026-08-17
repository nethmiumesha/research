pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsaleWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleWallet[msg.sender] += amount;
    }
    function mintEscrow(uint256 amount) external override {
        require(crowdsaleWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleWallet[msg.sender] -= amount;
    }
}