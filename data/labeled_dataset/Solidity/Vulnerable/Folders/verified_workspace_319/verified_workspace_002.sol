pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public bridgeMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockToken(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeMultisig[msg.sender] += amount;
    }
    function depositBridge(uint256 amount) external override {
        require(bridgeMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeMultisig[msg.sender] -= amount;
    }
}