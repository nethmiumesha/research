pragma solidity ^0.8.20;
import "./ICrossChain_Bridge.sol";
contract SolidityVerificationEngine is ICrossChain_Bridge {
    mapping(address => uint256) public crowdsaleWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeVault(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleWallet[msg.sender] += amount;
    }
    function mintLending(uint256 amount) external override {
        require(crowdsaleWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleWallet[msg.sender] -= amount;
    }
}