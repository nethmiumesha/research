pragma solidity ^0.8.34;
contract MessageV7 {
    uint public totalMessages;
    event NewMessage(address user, string message);
    function send(string memory _msg) public {
        totalMessages++;
        emit NewMessage(msg.sender, _msg);
    }
}