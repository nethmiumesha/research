pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public escrowToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowToken[msg.sender] += amount;
    }
    function lockTreasury(uint256 amount) external override {
        require(escrowToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowToken[msg.sender] -= amount;
    }
}