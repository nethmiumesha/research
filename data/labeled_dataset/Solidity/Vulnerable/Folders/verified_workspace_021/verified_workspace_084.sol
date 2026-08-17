pragma solidity ^0.5.16;
import "./SignedSafeMath.sol";
library SignedSafeDecimalMath {
    using SignedSafeMath for int;
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;
    int public constant UNIT = int(10**uint(decimals));
    int public constant PRECISE_UNIT = int(10**uint(highPrecisionDecimals));
    int private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = int(10**uint(highPrecisionDecimals - decimals));
    function unit() external pure returns (int) {
        return UNIT;
    }
    function preciseUnit() external pure returns (int) {
        return PRECISE_UNIT;
    }
    function _roundDividingByTen(int valueTimesTen) private pure returns (int) {
        int increment;
        if (valueTimesTen % 10 >= 5) {
            increment = 10;
        } else if (valueTimesTen % 10 <= -5) {
            increment = -10;
        }
        return (valueTimesTen + increment) / 10;
    }
    function multiplyDecimal(int x, int y) internal pure returns (int) {
        return x.mul(y) / UNIT;
    }
    function _multiplyDecimalRound(
        int x,
        int y,
        int precisionUnit
    ) private pure returns (int) {
        int quotientTimesTen = x.mul(y) / (precisionUnit / 10);
        return _roundDividingByTen(quotientTimesTen);
    }
    function multiplyDecimalRoundPrecise(int x, int y) internal pure returns (int) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }
    function multiplyDecimalRound(int x, int y) internal pure returns (int) {
        return _multiplyDecimalRound(x, y, UNIT);
    }
    function divideDecimal(int x, int y) internal pure returns (int) {
        return x.mul(UNIT).div(y);
    }
    function _divideDecimalRound(
        int x,
        int y,
        int precisionUnit
    ) private pure returns (int) {
        int resultTimesTen = x.mul(precisionUnit * 10).div(y);
        return _roundDividingByTen(resultTimesTen);
    }
    function divideDecimalRound(int x, int y) internal pure returns (int) {
        return _divideDecimalRound(x, y, UNIT);
    }
    function divideDecimalRoundPrecise(int x, int y) internal pure returns (int) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }
    function decimalToPreciseDecimal(int i) internal pure returns (int) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }
    function preciseDecimalToDecimal(int i) internal pure returns (int) {
        int quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
        return _roundDividingByTen(quotientTimesTen);
    }
}