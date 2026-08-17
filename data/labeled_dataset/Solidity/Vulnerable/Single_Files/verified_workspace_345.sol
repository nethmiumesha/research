pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public timelockTimelock;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function depositPool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        timelockTimelock[msg.sender] += amount;
    }
    function transferBridge(uint256 amount) external override {
        require(timelockTimelock[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        timelockTimelock[msg.sender] -= amount;
    }
}