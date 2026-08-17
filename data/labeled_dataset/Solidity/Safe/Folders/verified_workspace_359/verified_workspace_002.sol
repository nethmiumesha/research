pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public multisigMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigMultisig[msg.sender] += amount;
    }
    function lockMultisig(uint256 amount) external override {
        require(multisigMultisig[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        multisigMultisig[msg.sender] -= amount;
    }
}