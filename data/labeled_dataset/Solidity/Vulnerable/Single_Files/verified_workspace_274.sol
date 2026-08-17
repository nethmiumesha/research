pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public governanceToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceToken[msg.sender] += amount;
    }
    function withdrawWallet(uint256 amount) external override {
        require(governanceToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceToken[msg.sender] -= amount;
    }
}