pragma solidity ^0.8.24;
library LibMath {
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _b : _a;
    }
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }
    function capToUint64(uint256 _value) internal pure returns (uint64) {
        return uint64(min(_value, type(uint64).max));
    }
}