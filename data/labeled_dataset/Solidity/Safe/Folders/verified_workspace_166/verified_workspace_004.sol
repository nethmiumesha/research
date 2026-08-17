pragma solidity 0.5.17;
import "@openzeppelin/contracts/math/SafeMath.sol";
library MathUtils {
    using SafeMath for uint256;
    function within1(uint256 a, uint256 b) external pure returns (bool) {
        return (_difference(a, b) <= 1);
    }
    function difference(uint256 a, uint256 b) external pure returns (uint256) {
        return _difference(a, b);
    }
    function _difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a.sub(b);
        }
        return b.sub(a);
    }
}