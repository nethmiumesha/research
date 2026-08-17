pragma solidity ^0.8.17;
import {IAdapter} from "@interfaces/IAdapter.sol";
import {IERC20} from "@interfaces/IERC20.sol";
import {RefundLib} from "@libraries/RefundLib.sol";
import {SafeERC20} from "@libraries/SafeERC20.sol";
interface IOSwap {
    function swapExactTokensForTokens(
        address inToken,
        address outToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256[] memory amounts);
}
contract OriginArmAdapter is IAdapter {
    using SafeERC20 for IERC20;
    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _armSwap(to, pool, moreInfo);
    }
    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _armSwap(to, pool, moreInfo);
    }
    function _armSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        uint256 fromAmount = IERC20(fromToken).balanceOf(address(this));
        require(fromAmount > 0, "OriginArmAdapter: zero balance");
        IERC20(fromToken).forceApprove(pool, fromAmount);
        IOSwap(pool).swapExactTokensForTokens(fromToken, toToken, fromAmount, 0, to);
        IERC20(fromToken).forceApprove(pool, 0);
        RefundLib.refund(fromToken);
    }
}