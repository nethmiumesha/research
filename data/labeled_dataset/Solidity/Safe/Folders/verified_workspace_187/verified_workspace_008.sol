pragma solidity >=0.6.10 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
library SafeDecimalMath {
    using SafeMath for uint256;
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;
    uint256 private constant UNIT = 10**uint256(decimals);
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(UNIT);
    }
    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(PRECISE_UNIT);
    }
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT).div(y);
    }
    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(PRECISE_UNIT).div(y);
    }
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }
        return quotientTimesTen.div(10);
    }
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }
    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return saturatingMul(x, y).div(UNIT);
    }
}