pragma solidity ^0.8.24;
import { LogExpMath } from "./LogExpMath.sol";
library FixedPoint {
    error ZeroDivision();
    uint256 internal constant ONE = 1e18;
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000;
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return product / ONE;
    }
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;
        assembly ("memory-safe") {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 aInflated = a * ONE;
        return aInflated / b;
    }
    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        return mulDivUp(a, ONE, b);
    }
    function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 result) {
        if (c == 0) {
            revert ZeroDivision();
        }
        uint256 product = a * b;
        assembly ("memory-safe") {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), c), 1))
        }
    }
    function divUpRaw(uint256 a, uint256 b) internal pure returns (uint256 result) {
        if (b == 0) {
            revert ZeroDivision();
        }
        assembly ("memory-safe") {
            result := mul(iszero(iszero(a)), add(1, div(sub(a, 1), b)))
        }
    }
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;
            if (raw < maxError) {
                return 0;
            } else {
                unchecked {
                    return raw - maxError;
                }
            }
        }
    }
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;
            return raw + maxError;
        }
    }
    function complement(uint256 x) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := mul(lt(x, ONE), sub(ONE, x))
        }
    }
}