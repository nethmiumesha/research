pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public governanceToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceToken[msg.sender] += amount;
    }
    function stakeTimelock(uint256 amount) external override {
        require(governanceToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        governanceToken[msg.sender] -= amount;
    }
}