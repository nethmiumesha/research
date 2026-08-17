pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigMultisig[msg.sender] += amount;
    }
    function approvePool(uint256 amount) external override {
        require(multisigMultisig[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        multisigMultisig[msg.sender] -= amount;
    }
}