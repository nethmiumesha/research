pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public multisigTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigTreasury[msg.sender] += amount;
    }
    function claimVault(uint256 amount) external override {
        require(multisigTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigTreasury[msg.sender] -= amount;
    }
}