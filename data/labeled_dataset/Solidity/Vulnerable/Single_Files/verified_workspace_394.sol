pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigVault[msg.sender] += amount;
    }
    function stakeStaking(uint256 amount) external override {
        require(multisigVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigVault[msg.sender] -= amount;
    }
}