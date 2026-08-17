pragma solidity ^0.8.4;
import "./IUniswapOracle.sol";
import "../refs/CoreRef.sol";
import "../external/UniswapV2OracleLibrary.sol";
contract UniswapOracle is IUniswapOracle, CoreRef {
    using Decimal for Decimal.D256;
    IUniswapV2Pair public override pair;
    bool private isPrice0;
    uint256 public override priorCumulative;
    uint32 public override priorTimestamp;
    Decimal.D256 private twap = Decimal.zero();
    uint256 public override duration;
    uint256 private constant FIXED_POINT_GRANULARITY = 2**112;
    uint256 private constant USDC_DECIMALS_MULTIPLIER = 1e12;
    constructor(
        address _core,
        address _pair,
        uint256 _duration,
        bool _isPrice0
    ) CoreRef(_core) {
        pair = IUniswapV2Pair(_pair);
        isPrice0 = _isPrice0;
        duration = _duration;
        _init();
    }
    function update() external override whenNotPaused {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 currentTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 deltaTimestamp;
        unchecked {
            deltaTimestamp = currentTimestamp - priorTimestamp;
        }
        if (deltaTimestamp < duration) {
            return;
        }
        uint256 currentCumulative = _getCumulative(price0Cumulative, price1Cumulative);
        uint256 deltaCumulative;
        unchecked {
            deltaCumulative = (currentCumulative - priorCumulative);
        }
        deltaCumulative = deltaCumulative * USDC_DECIMALS_MULTIPLIER;
        Decimal.D256 memory _twap =
            Decimal.ratio(
                deltaCumulative / deltaTimestamp,
                FIXED_POINT_GRANULARITY
            );
        twap = _twap;
        priorTimestamp = currentTimestamp;
        priorCumulative = currentCumulative;
        emit Update(_twap.asUint256());
    }
    function isOutdated() external view override returns (bool) {
        (, , uint32 currentTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 deltaTimestamp = currentTimestamp - priorTimestamp;
        return deltaTimestamp >= duration;
    }
    function read() external view override returns (Decimal.D256 memory, bool) {
        bool valid = !(paused() || twap.isZero());
        return (twap, valid);
    }
    function setDuration(uint256 _duration) external override onlyGovernor {
        require(_duration != 0, "UniswapOracle: zero duration");
        duration = _duration;
        emit TWAPDurationUpdate(_duration);
    }
    function _init() internal {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 currentTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        priorTimestamp = currentTimestamp;
        priorCumulative = _getCumulative(price0Cumulative, price1Cumulative);
    }
    function _getCumulative(uint256 price0Cumulative, uint256 price1Cumulative)
        internal
        view
        returns (uint256)
    {
        return isPrice0 ? price0Cumulative : price1Cumulative;
    }
}