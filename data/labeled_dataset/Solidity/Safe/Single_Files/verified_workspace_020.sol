pragma solidity 0.8.34;
contract HakCipta {
    mapping(string => address) public pencipta;
    function klaim(string memory _teks) public {
        if(pencipta[_teks] == address(0)) pencipta[_teks] = msg.sender;
    }
}