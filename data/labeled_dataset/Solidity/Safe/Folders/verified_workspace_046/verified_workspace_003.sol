pragma solidity 0.6.10;
library MathUtils {
    uint constant private _EPS = 1e6;
    event UnderflowError(
        uint a,
        uint b
    );
    function boundedSub(uint256 a, uint256 b) internal returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            emit UnderflowError(a, b);
            return 0;
        }
    }
    function boundedSubWithoutEvent(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return 0;
        }
    }
    function muchGreater(uint256 a, uint256 b) internal pure returns (bool) {
        assert(uint(-1) - _EPS > b);
        return a > b + _EPS;
    }
    function approximatelyEqual(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b < _EPS;
        } else {
            return b - a < _EPS;
        }
    }
}