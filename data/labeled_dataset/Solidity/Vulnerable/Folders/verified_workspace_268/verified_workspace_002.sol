pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public lendingMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        lendingMultisig[msg.sender] += amount;
    }
    function stakeStaking(uint256 amount) external override {
        require(lendingMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        lendingMultisig[msg.sender] -= amount;
    }
}