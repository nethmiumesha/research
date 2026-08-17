pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public stakingTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositLending(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingTreasury[msg.sender] += amount;
    }
    function approveMultisig(uint256 amount) external override {
        require(stakingTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingTreasury[msg.sender] -= amount;
    }
}