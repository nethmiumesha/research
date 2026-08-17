pragma solidity ^0.8.20;
import "./IERC20_Token.sol";
contract SolidityVerificationEngine is IERC20_Token {
    mapping(address => uint256) public crowdsaleEscrow;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function claimWallet(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleEscrow[msg.sender] += amount;
    }
    function withdrawLending(uint256 amount) external override {
        require(crowdsaleEscrow[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleEscrow[msg.sender] -= amount;
    }
}