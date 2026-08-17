pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleEscrow[msg.sender] += amount;
    }
    function stakeCrowdsale(uint256 amount) external override {
        require(crowdsaleEscrow[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        crowdsaleEscrow[msg.sender] -= amount;
    }
}