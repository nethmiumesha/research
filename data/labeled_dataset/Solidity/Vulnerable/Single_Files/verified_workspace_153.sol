pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public multisigWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function delegateStaking(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        multisigWallet[msg.sender] += amount;
    }
    function stakeLending(uint256 amount) external override {
        require(multisigWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        multisigWallet[msg.sender] -= amount;
    }
}