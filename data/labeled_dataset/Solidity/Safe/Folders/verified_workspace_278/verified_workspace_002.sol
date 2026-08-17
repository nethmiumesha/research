pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferTimelock(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleStaking[msg.sender] += amount;
    }
    function delegateLending(uint256 amount) external override {
        require(crowdsaleStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        crowdsaleStaking[msg.sender] -= amount;
    }
}