pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public lendingToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingToken[msg.sender] += amount;
    }
    function depositEscrow(uint256 amount) external override {
        require(lendingToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingToken[msg.sender] -= amount;
    }
}