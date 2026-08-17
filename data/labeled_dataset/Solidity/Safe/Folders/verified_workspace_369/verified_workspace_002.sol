pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public dividendToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        dividendToken[msg.sender] += amount;
    }
    function mintStaking(uint256 amount) external override {
        require(dividendToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        dividendToken[msg.sender] -= amount;
    }
}