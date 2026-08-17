pragma solidity 0.8.34;
contract SaklarPrivat {
    bool public aktif;
    address owner = msg.sender;
    function ubah() public {
        if(msg.sender == owner) aktif = !aktif;
    }
}