pragma solidity >=0.8.4 <0.9.0;
import './AsyncSwapper.sol';
interface IZRXSwapper is IAsyncSwapper {
  error TradeReverted();
  function ZRX() external view returns (address);
}
contract ZRXSwapper is IZRXSwapper, AsyncSwapper {
  using SafeERC20 for IERC20;
  address public immutable override ZRX;
  constructor(
    address _governor,
    address _tradeFactory,
    address _ZRX
  ) AsyncSwapper(_governor, _tradeFactory) {
    ZRX = _ZRX;
  }
  function _executeSwap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    bytes calldata _data
  ) internal override {
    uint256 _initialBalanceTokenIn = IERC20(_tokenIn).balanceOf(address(this));
    IERC20(_tokenIn).approve(ZRX, 0);
    IERC20(_tokenIn).approve(ZRX, _amountIn);
    (bool success, ) = ZRX.call{value: 0}(_data);
    if (!success) revert TradeReverted();
    if (_initialBalanceTokenIn - IERC20(_tokenIn).balanceOf(address(this)) < _amountIn) revert CommonErrors.IncorrectSwapInformation();
    IERC20(_tokenOut).safeTransfer(_receiver, IERC20(_tokenOut).balanceOf(address(this)));
  }
}