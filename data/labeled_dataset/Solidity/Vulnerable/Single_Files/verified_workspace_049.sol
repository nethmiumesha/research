pragma solidity ^0.8.34;
contract SimpleStorage {
    uint public value;
    function set(uint _value) public {
        value = _value;
    }
}