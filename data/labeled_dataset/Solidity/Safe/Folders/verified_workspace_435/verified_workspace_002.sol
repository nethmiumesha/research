pragma solidity ^0.8.20;
import "./INFT_Marketplace.sol";
contract SolidityVerificationEngine is INFT_Marketplace {
    mapping(address => uint256) public multisigToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function lockMultisig(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigToken[msg.sender] += amount;
    }
    function transferEscrow(uint256 amount) external override {
        require(multisigToken[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        multisigToken[msg.sender] -= amount;
    }
}