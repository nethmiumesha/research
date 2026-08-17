pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public tokenWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function freezeGovernance(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        tokenWallet[msg.sender] += amount;
    }
    function transferToken(uint256 amount) external override {
        require(tokenWallet[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        tokenWallet[msg.sender] -= amount;
    }
}