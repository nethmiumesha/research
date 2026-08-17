pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public vaultStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function approveStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultStaking[msg.sender] += amount;
    }
    function freezeToken(uint256 amount) external override {
        require(vaultStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        vaultStaking[msg.sender] -= amount;
    }
}