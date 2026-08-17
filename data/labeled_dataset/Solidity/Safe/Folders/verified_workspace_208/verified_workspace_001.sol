pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ISwapper.sol";
contract SushiSwapSwapper is ISwapper {
    using BoringMath for uint256;
    IBentoBox public bentoBox;
    IUniswapV2Factory public factory;
    constructor(IBentoBox bentoBox_, IUniswapV2Factory factory_) public {
        bentoBox = bentoBox_;
        factory = factory_;
    }
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
    function swap(IERC20 from, IERC20 to, uint256 amountFrom, uint256 amountToMin) public override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(from), address(to)));
        bentoBox.withdraw(from, address(pair), amountFrom);
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountTo;
        if (pair.token0() == address(from)) {
            amountTo = getAmountOut(amountFrom, reserve0, reserve1);
            require(amountTo >= amountToMin, "SushiSwapSwapper: not enough");
            pair.swap(0, amountTo, address(bentoBox), new bytes(0));
        } else {
            amountTo = getAmountOut(amountFrom, reserve1, reserve0);
            require(amountTo >= amountToMin, "SushiSwapSwapper: not enough");
            pair.swap(amountTo, 0, address(bentoBox), new bytes(0));
        }
        return amountTo;
    }
    function swapExact(
        IERC20 from, IERC20 to, uint256 amountFromMax, uint256 exactAmountTo, address refundTo
    ) public override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(from), address(to)));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountFrom;
        if (pair.token0() == address(from)) {
            amountFrom = getAmountIn(exactAmountTo, reserve0, reserve1);
            require(amountFrom <= amountFromMax, "SushiSwapSwapper: not enough");
            bentoBox.withdraw(from, address(pair), amountFrom);
            pair.swap(0, exactAmountTo, address(bentoBox), new bytes(0));
        } else {
            amountFrom = getAmountIn(exactAmountTo, reserve1, reserve0);
            require(amountFrom <= amountFromMax, "SushiSwapSwapper: not enough");
            bentoBox.withdraw(from, address(pair), amountFrom);
            pair.swap(exactAmountTo, 0, address(bentoBox), new bytes(0));
        }
        bentoBox.transferFrom(from, address(this), refundTo, amountFromMax.sub(amountFrom));
        return amountFrom;
    }
}