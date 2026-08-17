pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public bridgeCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function transferMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeCrowdsale[msg.sender] += amount;
    }
    function mintToken(uint256 amount) external override {
        require(bridgeCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeCrowdsale[msg.sender] -= amount;
    }
}