pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public timelockGovernance;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockGovernance[msg.sender] += amount;
    }
    function withdrawMultisig(uint256 amount) external override {
        require(timelockGovernance[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockGovernance[msg.sender] -= amount;
    }
}