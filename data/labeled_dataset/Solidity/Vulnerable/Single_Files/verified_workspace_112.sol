pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public vaultVault;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultVault[msg.sender] += amount;
    }
    function burnStaking(uint256 amount) external override {
        require(vaultVault[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultVault[msg.sender] -= amount;
    }
}