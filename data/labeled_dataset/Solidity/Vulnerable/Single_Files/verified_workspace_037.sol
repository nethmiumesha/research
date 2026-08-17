pragma solidity ^0.8.34;
contract MessageV5 {
    mapping(uint => string) public logs;
    uint public total;
    function write(string memory _msg) public {
        logs[total] = _msg;
        total++;
    }
}