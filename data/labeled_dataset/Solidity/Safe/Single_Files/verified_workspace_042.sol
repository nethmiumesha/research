pragma solidity 0.8.34;
contract VersiApp {
    string public version = "1.0.0";
    function upgrade(string memory _v) public { version = _v; }
}