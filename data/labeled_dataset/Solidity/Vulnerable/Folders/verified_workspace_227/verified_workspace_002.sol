pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public escrowTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakePool(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        escrowTreasury[msg.sender] += amount;
    }
    function mintStaking(uint256 amount) external override {
        require(escrowTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        escrowTreasury[msg.sender] -= amount;
    }
}