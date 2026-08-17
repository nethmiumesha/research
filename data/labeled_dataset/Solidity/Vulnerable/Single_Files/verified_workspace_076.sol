pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public crowdsaleGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleGovernance[msg.sender] += amount;
    }
    function delegateBridge(uint256 amount) external override {
        require(crowdsaleGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleGovernance[msg.sender] -= amount;
    }
}