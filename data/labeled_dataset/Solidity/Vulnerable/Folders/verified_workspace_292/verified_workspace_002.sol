pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public stakingStaking;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeBridge(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        stakingStaking[msg.sender] += amount;
    }
    function depositDividend(uint256 amount) external override {
        require(stakingStaking[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        stakingStaking[msg.sender] -= amount;
    }
}