pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public multisigWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimCrowdsale(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigWallet[msg.sender] += amount;
    }
    function delegateToken(uint256 amount) external override {
        require(multisigWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigWallet[msg.sender] -= amount;
    }
}