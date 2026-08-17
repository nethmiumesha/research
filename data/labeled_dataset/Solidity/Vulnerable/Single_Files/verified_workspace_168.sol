pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public vaultTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintDividend(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultTimelock[msg.sender] += amount;
    }
    function transferStaking(uint256 amount) external override {
        require(vaultTimelock[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        vaultTimelock[msg.sender] -= amount;
    }
}