pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public crowdsaleMultisig;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function emergencyWithdrawGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleMultisig[msg.sender] += amount;
    }
    function depositPool(uint256 amount) external override {
        require(crowdsaleMultisig[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleMultisig[msg.sender] -= amount;
    }
}