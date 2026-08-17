pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgeGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeGovernance[msg.sender] += amount;
    }
    function transferBridge(uint256 amount) external override {
        require(bridgeGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeGovernance[msg.sender] -= amount;
    }
}