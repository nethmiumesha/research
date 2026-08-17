pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public crowdsaleGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleGovernance[msg.sender] += amount;
    }
    function depositTreasury(uint256 amount) external override {
        require(crowdsaleGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleGovernance[msg.sender] -= amount;
    }
}