pragma solidity ^0.5.16;
contract MathHelpers {
    function scientific(uint val, uint expTen) internal pure returns (uint) {
        return val * ( 10 ** expTen );
    }
}