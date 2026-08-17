pragma solidity 0.5.11;
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
library StableMath {
    using SafeMath for uint256;
    uint256 private constant FULL_SCALE = 1e18;
    function scaleBy(uint256 x, int8 adjustment)
        internal
        pure
        returns (uint256)
    {
        if (adjustment > 0) {
            x = x.mul(10**uint256(adjustment));
        } else if (adjustment < 0) {
            x = x.div(10**uint256(adjustment * -1));
        }
        return x;
    }
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        uint256 z = x.mul(y);
        return z.div(scale);
    }
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        uint256 scaled = x.mul(y);
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        return ceil.div(FULL_SCALE);
    }
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        uint256 z = x.mul(FULL_SCALE);
        return z.div(y);
    }
}