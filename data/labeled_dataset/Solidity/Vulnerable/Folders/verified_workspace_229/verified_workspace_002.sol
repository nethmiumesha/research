pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public escrowWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowWallet[msg.sender] += amount;
    }
    function transferLending(uint256 amount) external override {
        require(escrowWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowWallet[msg.sender] -= amount;
    }
}