pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public bridgeCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeCrowdsale[msg.sender] += amount;
    }
    function depositStaking(uint256 amount) external override {
        require(bridgeCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeCrowdsale[msg.sender] -= amount;
    }
}