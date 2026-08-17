pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}
interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function getCurrencyReserves(address currency) external view returns (uint256);
    function take(address currency, address to, uint256 amount) external;
    function settle(address currency) external payable returns (uint256 paid);
    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (int256 delta);
}
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}
interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}
contract OptimizedArbitrageFlashSwapperV4 is Ownable, IUniswapV2Callee, IUniswapV3SwapCallback, IUnlockCallback {
    using SafeERC20 for IERC20;
    enum PoolVersion {
        UniswapV2,
        UniswapV3,
        SushiSwapV2,
        PancakeSwapV2,
        SushiSwapV3,
        PancakeSwapV3,
        UniswapV4
    }
    uint256 private constant UNISWAP_V2_FEE = 30;
    uint256 private constant SUSHISWAP_FEE = 30;
    uint256 private constant PANCAKESWAP_FEE = 25;
    IPoolManager public immutable poolManager;
    address public immutable WETH;
    error SlippageExceeded(uint256 received, uint256 minimum);
    error TransferFailed(string context, address token, address to, uint256 amount, uint256 balance);
    error PoolCallbackFailed(address pool, address token, uint256 amount);
    error ArbitrageUnprofitable(uint256 finalAmount, uint256 requiredAmount);
    error InvalidSwapPath(string reason);
    error InsufficientProfit(uint256 actualProfit, uint256 minProfit);
    error UnsupportedPoolVersion(PoolVersion version);
    error SwapFailed(uint256 swapIndex, PoolVersion version, address pool, address tokenIn, uint256 amountIn, string reason);
    error InsufficientBalance(string context, address token, uint256 required, uint256 available);
    error V4OnlyCaller(address caller);
    error TipTransferFailed(address coinbase, uint256 amount);
    event ArbitrageExecuted(
        address indexed tokenBorrowed,
        uint256 amountBorrowed,
        uint256 finalAmount,
        address tokenRepaidWith,
        uint256 repaymentAmount
    );
    event ArbitrageStarted(address indexed pool, address tokenBorrow, uint256 amountBorrow);
    event ArbitrageError(string reason);
    event SwapExecuted(address tokenIn, address tokenOut, address pool, uint256 amountIn, uint256 amountOut, PoolVersion version);
    event DebugBalance(string context, address token, uint256 balance);
    event DebugSwapStart(uint256 swapIndex, address tokenIn, address tokenOut, uint256 amountIn);
    event ValidatorTipSent(address indexed coinbase, uint256 tipAmount, uint256 gasUsed, uint256 gasCost);
    event GasAdjustedTip(uint256 originalTip, uint256 adjustedTip, uint256 gasCost, uint256 retainedProfit);
    event TipSkipped(string reason, uint256 profit, uint256 gasCost);
    struct ArbSwap {
        PoolVersion version;
        address pool;
        address tokenIn;
        address tokenOut;
        uint160 sqrtPriceLimitX96;
        uint256 amountOutMin;
        address v4Hooks;
        uint24 v4Fee;
        int24 v4TickSpacing;
        bool useNativeETH;
    }
    struct CallbackData {
        address originator;
        address tokenBorrow;
        uint256 amountBorrow;
        PoolVersion sourcePoolVersion;
        ArbSwap[] swaps;
        uint256 minProfit;
        uint256 tipPercentageBps;
        uint256 minTipAmount;
        uint256 gasSafetyMarginBps;
        uint256 startGas;
    }
    constructor(address _poolManager, address _weth) Ownable(msg.sender) {
        require(_poolManager != address(0), "Invalid PoolManager address");
        require(_weth != address(0), "Invalid WETH address");
        poolManager = IPoolManager(_poolManager);
        WETH = _weth;
    }
    address private activePool;
    function executeArbitrage(
        address tokenBorrow,
        uint256 amountToBorrow,
        ArbSwap[] calldata swaps,
        uint256 minProfit,
        uint256 tipPercentageBps,
        uint256 minTipAmount,
        uint256 gasSafetyMarginBps
    ) external onlyOwner {
        uint256 startGas = gasleft();
        if (swaps.length < 2) {
            revert InvalidSwapPath("At least two pools required");
        }
        require(tipPercentageBps <= 10000, "Tip percentage cannot exceed 100%");
        ArbSwap memory firstSwap = swaps[0];
        require(firstSwap.tokenOut == tokenBorrow, "First swap tokenOut must match borrowed token");
        ArbSwap memory lastSwap = swaps[swaps.length-1];
        require(lastSwap.tokenOut == firstSwap.tokenIn, "Last swap tokenOut must match first swap tokenIn");
        CallbackData memory data = CallbackData({
            originator: msg.sender,
            tokenBorrow: tokenBorrow,
            amountBorrow: amountToBorrow,
            sourcePoolVersion: firstSwap.version,
            swaps: swaps,
            minProfit: minProfit,
            tipPercentageBps: tipPercentageBps,
            minTipAmount: minTipAmount,
            gasSafetyMarginBps: gasSafetyMarginBps,
            startGas: startGas
        });
        bytes memory encodedData = abi.encode(data);
        emit ArbitrageStarted(firstSwap.pool, tokenBorrow, amountToBorrow);
        if (firstSwap.version == PoolVersion.UniswapV4) {
            poolManager.unlock(encodedData);
        } else if (
            firstSwap.version == PoolVersion.UniswapV2 ||
            firstSwap.version == PoolVersion.SushiSwapV2 ||
            firstSwap.version == PoolVersion.PancakeSwapV2
        ) {
            _executeV2FlashSwap(firstSwap.pool, tokenBorrow, amountToBorrow, encodedData);
        } else {
            revert InvalidSwapPath("First pool must be V2 or V4 for flash loan");
        }
    }
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        if (msg.sender != address(poolManager)) {
            revert V4OnlyCaller(msg.sender);
        }
        uint256 actionType = abi.decode(data, (uint256));
        if (actionType == 1) {
            return _handleSwapCallback(data);
        } else {
            return _handleFlashLoanCallback(data);
        }
    }
    function _handleSwapCallback(bytes calldata data) internal returns (bytes memory) {
        (, PoolKey memory key, SwapParams memory params, address tokenIn, uint256 amountIn, bool useNativeETH) =
            abi.decode(data, (uint256, PoolKey, SwapParams, address, uint256, bool));
        int256 delta = IPoolManager(poolManager).swap(key, params, new bytes(0));
        int128 amount0 = int128(delta >> 128);
        int128 amount1 = int128(delta);
        uint256 amountOut;
        if (amount0 > 0) {
            uint256 amt = uint256(int256(amount0));
            if (useNativeETH && key.currency0 == address(0)) {
                IWETH(WETH).withdraw(amt);
                IPoolManager(poolManager).settle{value: amt}(address(0));
            } else {
                IERC20(key.currency0).safeTransfer(address(poolManager), amt);
                IPoolManager(poolManager).settle(key.currency0);
            }
        } else if (amount0 < 0) {
            uint256 takeAmount = uint256(int256(-amount0));
            IPoolManager(poolManager).take(key.currency0, address(this), takeAmount);
            if (useNativeETH && key.currency0 == address(0)) {
                IWETH(WETH).deposit{value: takeAmount}();
            }
            if (key.currency0 != tokenIn) amountOut = takeAmount;
        }
        if (amount1 > 0) {
            uint256 amt = uint256(int256(amount1));
            if (useNativeETH && key.currency1 == address(0)) {
                IWETH(WETH).withdraw(amt);
                IPoolManager(poolManager).settle{value: amt}(address(0));
            } else {
                IERC20(key.currency1).safeTransfer(address(poolManager), amt);
                IPoolManager(poolManager).settle(key.currency1);
            }
        } else if (amount1 < 0) {
            uint256 takeAmount = uint256(int256(-amount1));
            IPoolManager(poolManager).take(key.currency1, address(this), takeAmount);
            if (useNativeETH && key.currency1 == address(0)) {
                IWETH(WETH).deposit{value: takeAmount}();
            }
            if (key.currency1 != tokenIn) amountOut = takeAmount;
        }
        return abi.encode(amountOut);
    }
    function _handleFlashLoanCallback(bytes calldata data) internal returns (bytes memory) {
        CallbackData memory cbData = abi.decode(data, (CallbackData));
        bool isNativeETHFlash = cbData.swaps[0].useNativeETH;
        address actualBorrowCurrency = isNativeETHFlash ? address(0) : cbData.tokenBorrow;
        poolManager.take(actualBorrowCurrency, address(this), cbData.amountBorrow);
        if (isNativeETHFlash) {
            IWETH(WETH).deposit{value: cbData.amountBorrow}();
        }
        uint256 currentAmount = cbData.amountBorrow;
        address currentToken = cbData.tokenBorrow;
        uint256 finalAmount = _executeArbitrageLogic(currentToken, currentAmount, cbData.swaps);
        require(finalAmount >= cbData.amountBorrow, "Unprofitable V4 Flash");
        uint256 profit = finalAmount - cbData.amountBorrow;
        if (profit < cbData.minProfit) {
            revert InsufficientProfit(profit, cbData.minProfit);
        }
        _tipValidatorGasAware(
            cbData.tokenBorrow,
            profit,
            cbData.tipPercentageBps,
            cbData.minTipAmount,
            cbData.gasSafetyMarginBps,
            cbData.startGas
        );
        if (isNativeETHFlash) {
            IWETH(WETH).withdraw(cbData.amountBorrow);
            poolManager.settle{value: cbData.amountBorrow}(address(0));
        } else {
            IERC20(cbData.tokenBorrow).safeTransfer(address(poolManager), cbData.amountBorrow);
            poolManager.settle(cbData.tokenBorrow);
        }
        emit ArbitrageExecuted(cbData.tokenBorrow, cbData.amountBorrow, finalAmount, cbData.tokenBorrow, cbData.amountBorrow);
        return "";
    }
    function _executeV2FlashSwap(
        address pool,
        address tokenBorrow,
        uint256 amountBorrow,
        bytes memory callbackData
    ) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        address token0 = pair.token0();
        bool isBorrowingToken0 = tokenBorrow == token0;
        uint amount0Out = isBorrowingToken0 ? amountBorrow : 0;
        uint amount1Out = isBorrowingToken0 ? 0 : amountBorrow;
        pair.swap(amount0Out, amount1Out, address(this), callbackData);
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        CallbackData memory cbData = abi.decode(data, (CallbackData));
        IUniswapV2Pair pair = IUniswapV2Pair(msg.sender);
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(msg.sender == cbData.swaps[0].pool, "Unauthorized V2 Callback");
        address tokenToRepayWith = cbData.swaps[0].tokenIn;
        uint256 finalAmount = _executeArbitrageLogic(cbData.tokenBorrow, cbData.amountBorrow, cbData.swaps);
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        uint reserveIn = tokenToRepayWith == token0 ? r0 : r1;
        uint reserveOut = cbData.tokenBorrow == token0 ? r0 : r1;
        uint amountToRepay = getAmountIn(cbData.amountBorrow, reserveIn, reserveOut, cbData.sourcePoolVersion);
        uint256 profit = finalAmount > amountToRepay ? finalAmount - amountToRepay : 0;
        if (profit < cbData.minProfit) {
            revert InsufficientProfit(profit, cbData.minProfit);
        }
        if (IERC20(tokenToRepayWith).balanceOf(address(this)) < amountToRepay) {
            revert ArbitrageUnprofitable(IERC20(tokenToRepayWith).balanceOf(address(this)), amountToRepay);
        }
        IERC20(tokenToRepayWith).safeTransfer(msg.sender, amountToRepay);
        _tipValidatorGasAware(
            tokenToRepayWith,
            profit,
            cbData.tipPercentageBps,
            cbData.minTipAmount,
            cbData.gasSafetyMarginBps,
            cbData.startGas
        );
        emit ArbitrageExecuted(cbData.tokenBorrow, cbData.amountBorrow, finalAmount, tokenToRepayWith, amountToRepay);
    }
    function _executeArbitrageLogic(
        address startToken,
        uint256 startAmount,
        ArbSwap[] memory swaps
    ) internal returns (uint256) {
        uint256 currentAmount = startAmount;
        address currentToken = startToken;
        for (uint i = 1; i < swaps.length; i++) {
            ArbSwap memory swap = swaps[i];
            require(swap.tokenIn == currentToken, "Token path mismatch");
            uint256 amountOut;
            if (swap.version == PoolVersion.UniswapV4) {
               amountOut = _swapV4(swap, currentAmount);
            } else if (
                swap.version == PoolVersion.UniswapV2 ||
                swap.version == PoolVersion.SushiSwapV2 ||
                swap.version == PoolVersion.PancakeSwapV2
            ) {
                amountOut = _swapV2(swap.pool, currentToken, currentAmount, swap.amountOutMin, swap.version);
            } else {
                amountOut = _swapV3(swap.pool, currentToken, currentAmount, swap.amountOutMin, swap.sqrtPriceLimitX96);
            }
            emit SwapExecuted(swap.tokenIn, swap.tokenOut, swap.pool, currentAmount, amountOut, swap.version);
            currentToken = swap.tokenOut;
            currentAmount = amountOut;
        }
        require(currentToken == swaps[0].tokenIn, "Did not return to expected token");
        return currentAmount;
    }
    function _swapV4(ArbSwap memory swap, uint256 amountIn) internal returns (uint256) {
        address t0 = swap.tokenIn < swap.tokenOut ? swap.tokenIn : swap.tokenOut;
        address t1 = swap.tokenIn < swap.tokenOut ? swap.tokenOut : swap.tokenIn;
        if (swap.useNativeETH) {
            if (t0 == WETH) t0 = address(0);
            if (t1 == WETH) t1 = address(0);
        }
        PoolKey memory key = PoolKey({
            currency0: t0,
            currency1: t1,
            fee: swap.v4Fee,
            tickSpacing: swap.v4TickSpacing,
            hooks: swap.v4Hooks
        });
        bool zeroForOne = swap.tokenIn < swap.tokenOut;
        if (swap.useNativeETH) {
            zeroForOne = (t0 == address(0)) ? (swap.tokenIn == WETH) : zeroForOne;
        }
        SwapParams memory params = SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: -int256(amountIn),
            sqrtPriceLimitX96: swap.sqrtPriceLimitX96 == 0
                ? (zeroForOne ? 4295128739 : 1461446703485210103287273052203988822378723970342)
                : swap.sqrtPriceLimitX96
        });
        bytes memory swapData = abi.encode(uint256(1), key, params, swap.tokenIn, amountIn, swap.useNativeETH);
        bytes memory result = poolManager.unlock(swapData);
        return abi.decode(result, (uint256));
    }
     function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, PoolVersion poolVersion) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint feeDenominator;
        if (poolVersion == PoolVersion.PancakeSwapV2) {
            feeDenominator = 1000 - 25;
        } else if (poolVersion == PoolVersion.SushiSwapV2) {
            feeDenominator = 1000 - 30;
        } else {
            feeDenominator = 1000 - 30;
        }
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * feeDenominator;
        amountIn = (numerator / denominator) + 1;
    }
    function _swapV2(address pool, address tokenIn, uint256 amountIn, uint256 amountOutMin, PoolVersion poolVersion) internal returns (uint256 amountOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        address token0 = pair.token0();
        bool isToken0 = tokenIn == token0;
        (uint112 reserveIn, uint112 reserveOut) = isToken0 ? (r0, r1) : (r1, r0);
        uint feeBps = (poolVersion == PoolVersion.PancakeSwapV2) ? PANCAKESWAP_FEE : UNISWAP_V2_FEE;
        amountOut = _calculateAmountOut(reserveIn, reserveOut, amountIn, feeBps);
        if (amountOut < amountOutMin) revert SlippageExceeded(amountOut, amountOutMin);
        IERC20(tokenIn).safeTransfer(pool, amountIn);
        (uint amount0Out, uint amount1Out) = isToken0 ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
    function _swapV3(address pool, address tokenIn, uint256 amountIn, uint256 amountOutMin, uint160 sqrt) internal returns (uint256 amountOut) {
        IUniswapV3Pool v3pool = IUniswapV3Pool(pool);
        bool zeroForOne = (tokenIn == v3pool.token0());
        activePool = pool;
        (int256 amt0, int256 amt1) = v3pool.swap(address(this), zeroForOne, int256(amountIn), sqrt, abi.encode(tokenIn));
        activePool = address(0);
        int256 outDelta = zeroForOne ? amt1 : amt0;
        amountOut = uint256(-outDelta);
        if (amountOut < amountOutMin) revert SlippageExceeded(amountOut, amountOutMin);
    }
    function _calculateAmountOut(uint112 reserveIn, uint112 reserveOut, uint256 amountIn, uint256 feeBps) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * (10000 - feeBps);
        return (amountInWithFee * reserveOut) / (reserveIn * 10000 + amountInWithFee);
    }
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        require(msg.sender == activePool && activePool != address(0), "Unauthorized V3 callback");
        address tokenIn = abi.decode(data, (address));
        if (amount0Delta > 0) IERC20(tokenIn).safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20(tokenIn).safeTransfer(msg.sender, uint256(amount1Delta));
    }
    function _tipValidatorGasAware(
        address profitToken,
        uint256 profitAmount,
        uint256 tipPercentageBps,
        uint256 minTipAmount,
        uint256 gasSafetyMarginBps,
        uint256 startGas
    ) internal {
        if (profitToken != WETH) {
            _tipValidatorSimple(profitAmount, tipPercentageBps, minTipAmount);
            return;
        }
        uint256 gasUsedSoFar = startGas - gasleft();
        uint256 estimatedTipGas = 35000;
        uint256 totalEstimatedGas = gasUsedSoFar + estimatedTipGas;
        uint256 gasCost = totalEstimatedGas * tx.gasprice;
        uint256 gasCostWithMargin = gasCost * (10000 + gasSafetyMarginBps) / 10000;
        uint256 desiredTip = (profitAmount * tipPercentageBps) / 10000;
        uint256 retainedAfterTip = profitAmount - desiredTip;
        if (retainedAfterTip < gasCostWithMargin) {
            if (profitAmount <= gasCostWithMargin) {
                emit TipSkipped("Profit below gas cost", profitAmount, gasCostWithMargin);
                return;
            }
            uint256 maxTip = profitAmount - gasCostWithMargin;
            uint256 adjustedTip = maxTip < desiredTip ? maxTip : desiredTip;
             if (adjustedTip < minTipAmount) {
                emit TipSkipped("Adjusted tip below minimum", adjustedTip, gasCostWithMargin);
                return;
            }
            emit GasAdjustedTip(desiredTip, adjustedTip, gasCostWithMargin, profitAmount - adjustedTip);
            _sendTip(adjustedTip, totalEstimatedGas, gasCost);
        } else {
             if (desiredTip < minTipAmount) {
                emit TipSkipped("Tip below minimum", desiredTip, gasCostWithMargin);
                return;
            }
            _sendTip(desiredTip, totalEstimatedGas, gasCost);
        }
    }
    function _sendTip(uint256 tipAmount, uint256 gasUsed, uint256 gasCost) internal {
        IWETH(WETH).withdraw(tipAmount);
        (bool success, ) = block.coinbase.call{value: tipAmount}("");
        if (!success) revert TipTransferFailed(block.coinbase, tipAmount);
        emit ValidatorTipSent(block.coinbase, tipAmount, gasUsed, gasCost);
    }
    function _tipValidatorSimple(uint256 profitAmount, uint256 tipPercentageBps, uint256 minTipAmount) internal {
        uint256 ethBalance = address(this).balance;
        if (ethBalance >= minTipAmount) {
            uint256 ethTipAmount = (ethBalance * tipPercentageBps) / 10000;
             if (ethTipAmount >= minTipAmount) {
                (bool success, ) = block.coinbase.call{value: ethTipAmount}("");
                if (success) emit ValidatorTipSent(block.coinbase, ethTipAmount, 0, 0);
            }
        }
    }
    receive() external payable {}
}