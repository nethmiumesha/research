pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleVault[msg.sender] += amount;
    }
    function freezeWallet(uint256 amount) external override {
        require(crowdsaleVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleVault[msg.sender] -= amount;
    }
}