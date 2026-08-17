pragma solidity 0.8.34;
contract Absen {
    mapping(address => bool) public sudahHadir;
    function masuk() public {
        sudahHadir[msg.sender] = true;
    }
}