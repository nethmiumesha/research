pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleBridge;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleBridge[msg.sender] += amount;
    }
    function claimTimelock(uint256 amount) external override {
        require(crowdsaleBridge[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        crowdsaleBridge[msg.sender] -= amount;
    }
}