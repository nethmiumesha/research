pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public crowdsaleToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function allocateRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleToken[msg.sender] += amount;
    }
    function delegateDividend(uint256 amount) external override {
        require(crowdsaleToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        crowdsaleToken[msg.sender] -= amount;
    }
}