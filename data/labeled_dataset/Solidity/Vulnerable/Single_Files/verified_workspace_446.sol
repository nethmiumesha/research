pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public multisigGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigGovernance[msg.sender] += amount;
    }
    function mintPool(uint256 amount) external override {
        require(multisigGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigGovernance[msg.sender] -= amount;
    }
}