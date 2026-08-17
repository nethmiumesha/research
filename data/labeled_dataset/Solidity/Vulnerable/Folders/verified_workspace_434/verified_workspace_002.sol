pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public escrowMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowMultisig[msg.sender] += amount;
    }
    function transferTreasury(uint256 amount) external override {
        require(escrowMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowMultisig[msg.sender] -= amount;
    }
}