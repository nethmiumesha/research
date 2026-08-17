pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public governanceLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceLending[msg.sender] += amount;
    }
    function withdrawWallet(uint256 amount) external override {
        require(governanceLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceLending[msg.sender] -= amount;
    }
}