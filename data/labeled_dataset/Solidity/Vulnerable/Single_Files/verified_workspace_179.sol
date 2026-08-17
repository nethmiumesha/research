pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public bridgeDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeDividend[msg.sender] += amount;
    }
    function delegateVault(uint256 amount) external override {
        require(bridgeDividend[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeDividend[msg.sender] -= amount;
    }
}