pragma solidity ^0.6.0;
abstract contract OracleInterface {
    function requestPrice(bytes32 identifier, uint256 time) public virtual;
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}