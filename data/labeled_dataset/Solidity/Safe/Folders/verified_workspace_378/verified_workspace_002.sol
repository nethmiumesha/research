pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public vaultGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultGovernance[msg.sender] += amount;
    }
    function transferLending(uint256 amount) external override {
        require(vaultGovernance[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        vaultGovernance[msg.sender] -= amount;
    }
}