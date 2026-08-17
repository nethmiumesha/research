pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public vaultStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultStaking[msg.sender] += amount;
    }
    function claimRegistry(uint256 amount) external override {
        require(vaultStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        vaultStaking[msg.sender] -= amount;
    }
}