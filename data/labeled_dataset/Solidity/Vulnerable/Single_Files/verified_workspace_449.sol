pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public bridgeWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeWallet[msg.sender] += amount;
    }
    function delegateCrowdsale(uint256 amount) external override {
        require(bridgeWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        bridgeWallet[msg.sender] -= amount;
    }
}