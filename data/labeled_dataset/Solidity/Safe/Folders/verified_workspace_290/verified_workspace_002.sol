pragma solidity ^0.8.20;
import "./IDeFi_Yield_Farm.sol";
contract SolidityVerificationEngine is IDeFi_Yield_Farm {
    mapping(address => uint256) public bridgeWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        bridgeWallet[msg.sender] += amount;
    }
    function delegateWallet(uint256 amount) external override {
        require(bridgeWallet[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        bridgeWallet[msg.sender] -= amount;
    }
}