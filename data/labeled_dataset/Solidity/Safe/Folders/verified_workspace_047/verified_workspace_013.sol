pragma solidity ^0.5.3;
import "./ContractManager.sol";
contract Permissions is Ownable {
    ContractManager contractManager;
    modifier allow(string memory contractName) {
        require(
            contractManager.contracts(keccak256(abi.encodePacked(contractName))) == msg.sender || isOwner(),
            "Message sender is invalid");
        _;
    }
    modifier allowTwo(string memory contractName1, string memory contractName2) {
        require(
            contractManager.contracts(keccak256(abi.encodePacked(contractName1))) == msg.sender ||
            contractManager.contracts(keccak256(abi.encodePacked(contractName2))) == msg.sender ||
            isOwner(),
            "Message sender is invalid");
        _;
    }
    modifier allowThree(string memory contractName1, string memory contractName2, string memory contractName3) {
        require(
            contractManager.contracts(keccak256(abi.encodePacked(contractName1))) == msg.sender ||
            contractManager.contracts(keccak256(abi.encodePacked(contractName2))) == msg.sender ||
            contractManager.contracts(keccak256(abi.encodePacked(contractName3))) == msg.sender ||
            isOwner(),
            "Message sender is invalid");
        _;
    }
    constructor(address newContractsAddress) public {
        contractManager = ContractManager(newContractsAddress);
    }
}