pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public vaultMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultMultisig[msg.sender] += amount;
    }
    function allocateMultisig(uint256 amount) external override {
        require(vaultMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultMultisig[msg.sender] -= amount;
    }
}