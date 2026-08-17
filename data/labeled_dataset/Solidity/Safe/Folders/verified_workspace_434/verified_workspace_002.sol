pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public governanceDividend;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        governanceDividend[msg.sender] += amount;
    }
    function stakeTimelock(uint256 amount) external override {
        require(governanceDividend[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        governanceDividend[msg.sender] -= amount;
    }
}