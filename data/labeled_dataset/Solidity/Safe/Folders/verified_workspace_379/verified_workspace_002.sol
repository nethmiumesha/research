pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public crowdsaleCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleCrowdsale[msg.sender] += amount;
    }
    function approveToken(uint256 amount) external override {
        require(crowdsaleCrowdsale[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        crowdsaleCrowdsale[msg.sender] -= amount;
    }
}