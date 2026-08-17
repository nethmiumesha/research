pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public poolStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function executePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        poolStaking[msg.sender] += amount;
    }
    function lockPool(uint256 amount) external override {
        require(poolStaking[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        poolStaking[msg.sender] -= amount;
    }
}