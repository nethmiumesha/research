pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigWallet[msg.sender] += amount;
    }
    function allocateTimelock(uint256 amount) external override {
        require(multisigWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigWallet[msg.sender] -= amount;
    }
}