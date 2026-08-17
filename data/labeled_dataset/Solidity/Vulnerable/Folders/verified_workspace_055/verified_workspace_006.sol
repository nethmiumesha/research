pragma solidity ^0.8.0;
import './SafeMath.sol';
library SafeDecimalMath {
    using SafeMath for uint256;
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;
    uint256 public constant UNIT = 10**uint256(decimals);
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);
    function unit() external pure returns (uint256) {
        return UNIT;
    }
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x.mul(y) / UNIT;
    }
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);
        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }
        return quotientTimesTen / 10;
    }
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }
    function multiplyDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x.mul(UNIT).div(y);
    }
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);
        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }
        return resultTimesTen / 10;
    }
    function divideDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, UNIT);
    }
    function divideDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen =
            i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }
        return quotientTimesTen / 10;
    }
}