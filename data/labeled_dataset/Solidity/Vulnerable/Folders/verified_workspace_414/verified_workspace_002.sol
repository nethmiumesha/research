pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public crowdsaleStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleStaking[msg.sender] += amount;
    }
    function allocateLending(uint256 amount) external override {
        require(crowdsaleStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleStaking[msg.sender] -= amount;
    }
}