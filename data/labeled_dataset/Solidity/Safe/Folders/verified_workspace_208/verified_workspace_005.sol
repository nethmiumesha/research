pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "../libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";
contract SimpleSLPTWAP0Oracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 5 minutes;
    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 priceAverage;
    }
    mapping(IUniswapV2Pair => PairInfo) public pairs;
    mapping(address => IUniswapV2Pair) public callerInfo;
    function _get(IUniswapV2Pair pair, uint32 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = pair.price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            priceCumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * (blockTimestamp - blockTimestampLast);
        }
        return priceCumulative;
    }
    function getDataParameter(IUniswapV2Pair pair) public pure returns (bytes memory) { return abi.encode(pair); }
    function get(bytes calldata data) external override returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            pairs[pair].blockTimestampLast = blockTimestamp;
            pairs[pair].priceCumulativeLast = _get(pair, blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast;
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }
        uint256 priceCumulative = _get(pair, blockTimestamp);
        pairs[pair].priceAverage = FixedPoint.uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));
        pairs[pair].blockTimestampLast = blockTimestamp;
        pairs[pair].priceCumulativeLast = priceCumulative;
        return (true, pairs[pair].priceAverage.mul(10**18).decode144());
    }
    function peek(bytes calldata data) public override view returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast;
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }
        uint256 priceCumulative = _get(pair, blockTimestamp);
        FixedPoint.uq112x112 memory priceAverage = FixedPoint
            .uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));
        return (true, priceAverage.mul(10**18).decode144());
    }
    function name(bytes calldata) public override view returns (string memory) {
        return "SushiSwap TWAP";
    }
    function symbol(bytes calldata) public override view returns (string memory) {
        return "S";
    }
}