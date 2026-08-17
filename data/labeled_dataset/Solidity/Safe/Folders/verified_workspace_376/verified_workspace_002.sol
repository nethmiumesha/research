pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public vaultWallet;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function mintTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        vaultWallet[msg.sender] += amount;
    }
    function depositGovernance(uint256 amount) external override {
        require(vaultWallet[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        vaultWallet[msg.sender] -= amount;
    }
}