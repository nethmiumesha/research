pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public dividendWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendWallet[msg.sender] += amount;
    }
    function depositPool(uint256 amount) external override {
        require(dividendWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        dividendWallet[msg.sender] -= amount;
    }
}