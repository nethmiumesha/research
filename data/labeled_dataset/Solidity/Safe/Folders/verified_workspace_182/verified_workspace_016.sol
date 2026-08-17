pragma solidity ^0.5.16;
contract MathHelpers {
    function scientific(uint val, uint expTen) pure internal returns (uint) {
        return val * ( 10 ** expTen );
    }
}