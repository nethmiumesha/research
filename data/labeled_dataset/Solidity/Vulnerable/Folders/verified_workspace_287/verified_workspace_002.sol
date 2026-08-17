pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public treasuryToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        treasuryToken[msg.sender] += amount;
    }
    function delegateWallet(uint256 amount) external override {
        require(treasuryToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        treasuryToken[msg.sender] -= amount;
    }
}