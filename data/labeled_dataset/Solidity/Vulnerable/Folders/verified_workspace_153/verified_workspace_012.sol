pragma solidity 0.8.33;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IRouter} from "../interfaces/periphery/IRouter.sol";
contract Router is IRouter, ReentrancyGuard {
    /
    using SafeERC20 for IERC20;
    /
    error Router__ZeroAddress();
    error Router__ZeroAmount();
    error Router__SlippageExceeded();
    error Router__ETHWrapFailed();
    error Router__FundsStuck();
    error Router__UseVaultForWETH();
    error Router__UnauthorizedETHSender();
    error Router__ETHUnwrapFailed();
    /
    constructor(address _weth, address _vault, address _swap_router) {
        if (_weth == address(0)) revert Router__ZeroAddress();
        if (_vault == address(0)) revert Router__ZeroAddress();
        if (_swap_router == address(0)) revert Router__ZeroAddress();
        weth = _weth;
        vault = _vault;
        swap_router = _swap_router;
        IERC20(_weth).forceApprove(_vault, type(uint256).max);
    }
    /
    function zapDepositETH() external payable nonReentrant returns (uint256 shares) {
        if (msg.value == 0) revert Router__ZeroAmount();
        _wrapETH(msg.value);
        shares = IERC4626(vault).deposit(msg.value, msg.sender);
        if (IERC20(weth).balanceOf(address(this)) != 0) revert Router__FundsStuck();
        emit ZapDeposit(msg.sender, address(0), msg.value, msg.value, shares);
    }
    function zapDepositERC20(address token_in, uint256 amount_in, uint24 pool_fee, uint256 min_weth_out)
        external
        nonReentrant
        returns (uint256 shares)
    {
        if (token_in == address(0)) revert Router__ZeroAddress();
        if (token_in == weth) revert Router__UseVaultForWETH();
        if (amount_in == 0) revert Router__ZeroAmount();
        IERC20(token_in).safeTransferFrom(msg.sender, address(this), amount_in);
        uint256 weth_out = _swapToWETH(token_in, amount_in, pool_fee, min_weth_out);
        shares = IERC4626(vault).deposit(weth_out, msg.sender);
        if (IERC20(weth).balanceOf(address(this)) != 0) revert Router__FundsStuck();
        emit ZapDeposit(msg.sender, token_in, amount_in, weth_out, shares);
    }
    function zapWithdrawETH(uint256 shares) external nonReentrant returns (uint256 eth_out) {
        if (shares == 0) revert Router__ZeroAmount();
        IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        uint256 weth_redeemed = IERC4626(vault).redeem(shares, address(this), address(this));
        eth_out = _unwrapWETH(weth_redeemed);
        (bool success,) = msg.sender.call{value: eth_out}("");
        if (!success) revert Router__ETHUnwrapFailed();
        if (IERC20(weth).balanceOf(address(this)) != 0) revert Router__FundsStuck();
        emit ZapWithdraw(msg.sender, shares, weth_redeemed, address(0), eth_out);
    }
    function zapWithdrawERC20(uint256 shares, address token_out, uint24 pool_fee, uint256 min_token_out)
        external
        nonReentrant
        returns (uint256 amount_out)
    {
        if (token_out == address(0)) revert Router__ZeroAddress();
        if (token_out == weth) revert Router__UseVaultForWETH();
        if (shares == 0) revert Router__ZeroAmount();
        IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        uint256 weth_redeemed = IERC4626(vault).redeem(shares, address(this), address(this));
        amount_out = _swapFromWETH(weth_redeemed, token_out, pool_fee, min_token_out);
        IERC20(token_out).safeTransfer(msg.sender, amount_out);
        if (IERC20(token_out).balanceOf(address(this)) != 0) revert Router__FundsStuck();
        emit ZapWithdraw(msg.sender, shares, weth_redeemed, token_out, amount_out);
    }
    /
    function _wrapETH(uint256 amount) internal {
        (bool success,) = weth.call{value: amount}(abi.encodeWithSignature("deposit()"));
        if (!success) revert Router__ETHWrapFailed();
    }
    function _unwrapWETH(uint256 amount) internal returns (uint256 eth_out) {
        (bool success,) = weth.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        if (!success) revert Router__ETHUnwrapFailed();
        eth_out = amount;
    }
    function _swapToWETH(address token_in, uint256 amount_in, uint24 pool_fee, uint256 min_weth_out)
        internal
        returns (uint256 weth_out)
    {
        IERC20(token_in).forceApprove(swap_router, amount_in);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: token_in,
            tokenOut: weth,
            fee: pool_fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount_in,
            amountOutMinimum: min_weth_out,
            sqrtPriceLimitX96: 0
        });
        weth_out = ISwapRouter(swap_router).exactInputSingle(params);
        if (weth_out < min_weth_out) revert Router__SlippageExceeded();
    }
    function _swapFromWETH(uint256 weth_in, address token_out, uint24 pool_fee, uint256 min_token_out)
        internal
        returns (uint256 amount_out)
    {
        IERC20(weth).forceApprove(swap_router, weth_in);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: token_out,
            fee: pool_fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: weth_in,
            amountOutMinimum: min_token_out,
            sqrtPriceLimitX96: 0
        });
        amount_out = ISwapRouter(swap_router).exactInputSingle(params);
        if (amount_out < min_token_out) revert Router__SlippageExceeded();
    }
    receive() external payable {
        if (msg.sender != weth) revert Router__UnauthorizedETHSender();
    }
}