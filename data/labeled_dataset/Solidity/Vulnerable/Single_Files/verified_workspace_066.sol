pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public multisigLending;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigLending[msg.sender] += amount;
    }
    function stakeStaking(uint256 amount) external override {
        require(multisigLending[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigLending[msg.sender] -= amount;
    }
}