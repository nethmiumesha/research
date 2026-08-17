pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { IPriceFeed } from "./interface/IPriceFeed.sol";
import { BlockContext } from "./base/BlockContext.sol";
contract EmergencyPriceFeed is IPriceFeed, BlockContext {
    using Address for address;
    address public pool;
    constructor(address poolArg) {
        require(address(poolArg).isContract(), "EPF_EANC");
        pool = poolArg;
    }
    function getPrice(uint256 interval) external view override returns (uint256) {
        uint256 markTwapX96 = _formatSqrtPriceX96ToPriceX96(_getSqrtMarkTwapX96(_toUint32(interval)));
        return _formatX96ToX10_18(markTwapX96);
    }
    function decimals() external pure override returns (uint8) {
        return 18;
    }
    function _getSqrtMarkTwapX96(uint32 twapInterval) internal view returns (uint160) {
        if (twapInterval < 10) {
            (uint160 sqrtMarkPrice, , , , , , ) = IUniswapV3Pool(pool).slot0();
            return sqrtMarkPrice;
        }
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);
        return TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval));
    }
    function _toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }
    function _formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
    function _formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1e18, FixedPoint96.Q96);
    }
}