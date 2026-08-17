pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigEscrow[msg.sender] += amount;
    }
    function allocateCrowdsale(uint256 amount) external override {
        require(multisigEscrow[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigEscrow[msg.sender] -= amount;
    }
}