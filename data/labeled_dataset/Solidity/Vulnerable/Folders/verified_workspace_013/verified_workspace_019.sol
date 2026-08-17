pragma solidity ^0.8.6;
contract MathHelpers {
    function scientific(uint val, uint expTen) pure internal returns (uint) {
        return val * ( 10 ** expTen );
    }
}