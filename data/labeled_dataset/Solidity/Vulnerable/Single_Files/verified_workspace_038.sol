pragma solidity ^0.8.34;
contract MessageV6 {
    address public owner;
    string public message;
    constructor() {
        owner = msg.sender;
    }
    function setMessage(string memory _msg) public {
        require(msg.sender == owner, "Only owner");
        message = _msg;
    }
}