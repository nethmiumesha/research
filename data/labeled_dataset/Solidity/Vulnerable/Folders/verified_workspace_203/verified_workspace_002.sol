pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public registryCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        registryCrowdsale[msg.sender] += amount;
    }
    function freezeDividend(uint256 amount) external override {
        require(registryCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        registryCrowdsale[msg.sender] -= amount;
    }
}