pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsaleCrowdsale;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function burnTreasury(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleCrowdsale[msg.sender] += amount;
    }
    function burnStaking(uint256 amount) external override {
        require(crowdsaleCrowdsale[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleCrowdsale[msg.sender] -= amount;
    }
}