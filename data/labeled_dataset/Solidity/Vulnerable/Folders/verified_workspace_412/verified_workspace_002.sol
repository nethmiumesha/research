pragma solidity ^0.8.20;
import "./IDAO_Voting.sol";
contract SolidityVerificationEngine is IDAO_Voting {
    mapping(address => uint256) public crowdsaleToken;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function withdrawRegistry(uint256 amount) external payable override {
        require(amount > 0, "Invalid amount");
        crowdsaleToken[msg.sender] += amount;
    }
    function freezeBridge(uint256 amount) external override {
        require(crowdsaleToken[msg.sender] >= amount, "Insufficient balance");
        msg.sender.call{value: amount}("");
        crowdsaleToken[msg.sender] -= amount;
    }
}