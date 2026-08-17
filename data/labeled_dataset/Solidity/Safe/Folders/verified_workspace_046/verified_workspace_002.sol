pragma solidity 0.6.10;
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
library FractionUtils {
    using SafeMath for uint;
    struct Fraction {
        uint numerator;
        uint denominator;
    }
    function createFraction(uint numerator, uint denominator) internal pure returns (Fraction memory) {
        require(denominator > 0, "Division by zero");
        Fraction memory fraction = Fraction({numerator: numerator, denominator: denominator});
        reduceFraction(fraction);
        return fraction;
    }
    function createFraction(uint value) internal pure returns (Fraction memory) {
        return createFraction(value, 1);
    }
    function reduceFraction(Fraction memory fraction) internal pure {
        uint _gcd = gcd(fraction.numerator, fraction.denominator);
        fraction.numerator = fraction.numerator.div(_gcd);
        fraction.denominator = fraction.denominator.div(_gcd);
    }
    function multiplyFraction(Fraction memory a, Fraction memory b) internal pure returns (Fraction memory) {
        return createFraction(a.numerator.mul(b.numerator), a.denominator.mul(b.denominator));
    }
    function gcd(uint a, uint b) internal pure returns (uint) {
        uint _a = a;
        uint _b = b;
        if (_b > _a) {
            (_a, _b) = swap(_a, _b);
        }
        while (_b > 0) {
            _a = _a.mod(_b);
            (_a, _b) = swap (_a, _b);
        }
        return _a;
    }
    function swap(uint a, uint b) internal pure returns (uint, uint) {
        return (b, a);
    }
}