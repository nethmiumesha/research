pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public timelockMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockMultisig[msg.sender] += amount;
    }
    function withdrawRegistry(uint256 amount) external override {
        require(timelockMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockMultisig[msg.sender] -= amount;
    }
}