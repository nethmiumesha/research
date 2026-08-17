pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public poolWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolWallet[msg.sender] += amount;
    }
    function burnCrowdsale(uint256 amount) external override {
        require(poolWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        poolWallet[msg.sender] -= amount;
    }
}