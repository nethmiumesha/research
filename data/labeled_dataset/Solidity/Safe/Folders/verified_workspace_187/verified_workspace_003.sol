pragma solidity >=0.6.10 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
abstract contract CoreUtility {
    using SafeMath for uint256;
    uint256 internal constant SETTLEMENT_TIME = 14 hours;
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}