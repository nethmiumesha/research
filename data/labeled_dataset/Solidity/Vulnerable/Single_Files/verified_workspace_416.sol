pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public tokenWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenWallet[msg.sender] += amount;
    }
    function mintVault(uint256 amount) external override {
        require(tokenWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenWallet[msg.sender] -= amount;
    }
}