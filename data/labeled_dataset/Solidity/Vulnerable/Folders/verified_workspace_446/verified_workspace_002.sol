pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigTreasury;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function stakeTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigTreasury[msg.sender] += amount;
    }
    function depositWallet(uint256 amount) external override {
        require(multisigTreasury[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigTreasury[msg.sender] -= amount;
    }
}