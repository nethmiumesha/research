pragma solidity ^0.4.24;
contract LightContract {
    address lib;
    constructor(address _library) public {
        lib = _library;
    }
    function() public {
        require(lib.delegatecall(msg.data));
    }
}