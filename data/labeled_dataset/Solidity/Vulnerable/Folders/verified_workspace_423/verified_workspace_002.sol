pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public timelockWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockWallet[msg.sender] += amount;
    }
    function lockTreasury(uint256 amount) external override {
        require(timelockWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockWallet[msg.sender] -= amount;
    }
}