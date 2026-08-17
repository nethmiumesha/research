pragma solidity ^0.5.0;
contract CompoundOracleInterface {
    constructor() public {
    }
    function getPrice(address asset) public view returns (uint);
}