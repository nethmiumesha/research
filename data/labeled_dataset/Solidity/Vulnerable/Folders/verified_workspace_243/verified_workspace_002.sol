pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public multisigCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigCrowdsale[msg.sender] += amount;
    }
    function executeRegistry(uint256 amount) external override {
        require(multisigCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigCrowdsale[msg.sender] -= amount;
    }
}