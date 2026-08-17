pragma solidity 0.6.12;
import "./CarefulMath.sol";
contract Exponential is CarefulMath {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;
    struct Exp {
        uint256 mantissa;
    }
    struct Double {
        uint256 mantissa;
    }
    function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);
        return (error, Exp({mantissa: result}));
    }
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);
        return (error, Exp({mantissa: result}));
    }
    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }
    function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }
        return (MathError.NO_ERROR, truncate(product));
    }
    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }
        return addUInt(truncate(product), addend);
    }
    function divScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }
    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }
        return (MathError.NO_ERROR, truncate(fraction));
    }
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        assert(err2 == MathError.NO_ERROR);
        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }
    function mulExp(uint256 a, uint256 b) internal pure returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
    function truncate(Exp memory exp) internal pure returns (uint256) {
        return exp.mantissa / expScale;
    }
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }
    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }
    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }
    function add_(uint256 a, uint256 b) internal pure returns (uint256) {
        return add_(a, b, "addition overflow");
    }
    function add_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }
    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }
    function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub_(a, b, "subtraction underflow");
    }
    function sub_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }
    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }
    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / expScale;
    }
    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }
    function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }
    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / doubleScale;
    }
    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul_(a, b, "multiplication overflow");
    }
    function mul_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }
    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }
    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }
    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return div_(mul_(a, expScale), b.mantissa);
    }
    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }
    function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }
    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }
    function div_(uint256 a, uint256 b) internal pure returns (uint256) {
        return div_(a, b, "divide by zero");
    }
    function div_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}