pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeEscrow(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleMultisig[msg.sender] += amount;
    }
    function approveWallet(uint256 amount) external override {
        require(crowdsaleMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleMultisig[msg.sender] -= amount;
    }
}