pragma solidity 0.8.34;
contract Messenger {
    string public pesan;
    function tulis(string memory _teks) public {
        pesan = _teks;
    }
}