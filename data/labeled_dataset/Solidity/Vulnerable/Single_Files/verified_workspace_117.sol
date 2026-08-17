pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public crowdsaleCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleCrowdsale[msg.sender] += amount;
    }
    function mintEscrow(uint256 amount) external override {
        require(crowdsaleCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleCrowdsale[msg.sender] -= amount;
    }
}