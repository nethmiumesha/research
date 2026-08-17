pragma solidity ^0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
contract DexUtils {
  using SafeMath for uint256;
  IUniswapV2Router02 uniswapV2Router;
  IUniswapV2Factory uniswapV2Factory;
  address public wrappedNative;
  address public stableToken;
  constructor(
    address _dexRouter,
    address _wrappedNative,
    address _stableToken
  ) {
    uniswapV2Router = IUniswapV2Router02(_dexRouter);
    uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
    wrappedNative = _wrappedNative;
    stableToken = _stableToken;
  }
  function getTokenPriceViaNativePair(address token)
    external
    view
    returns (uint256)
  {
    (
      uint256 mnPriceAdjusted,
      address mnToken0,
      address mnToken1
    ) = _getTokenPrice(token, wrappedNative);
    (
      uint256 nsPriceAdjusted,
      address nsToken0,
      address nsToken1
    ) = _getTokenPrice(wrappedNative, stableToken);
    if (mnToken0 == nsToken0) {
      return nsPriceAdjusted.mul(10**18).div(mnPriceAdjusted);
    } else if (mnToken1 == nsToken1) {
      return mnPriceAdjusted.mul(10**18).div(nsPriceAdjusted);
    } else if (mnToken1 == nsToken0) {
      return nsPriceAdjusted.mul(mnPriceAdjusted).div(uint256(10**18));
    }
    return uint256(10**54).div(nsPriceAdjusted.mul(mnPriceAdjusted));
  }
  function _getTokenPrice(address _t0, address _t1)
    private
    view
    returns (
      uint256,
      address,
      address
    )
  {
    IUniswapV2Pair dexPair = IUniswapV2Pair(uniswapV2Factory.getPair(_t0, _t1));
    (uint112 res0, uint112 res1, ) = dexPair.getReserves();
    address t0 = dexPair.token0();
    uint8 t0Dec = IERC20Decimals(t0).decimals();
    address t1 = dexPair.token1();
    uint8 t1Dec = IERC20Decimals(t1).decimals();
    return (
      uint256(res1).mul(10**18).mul(10**t0Dec).div(uint256(res0)).div(
        10**t1Dec
      ),
      t0,
      t1
    );
  }
}