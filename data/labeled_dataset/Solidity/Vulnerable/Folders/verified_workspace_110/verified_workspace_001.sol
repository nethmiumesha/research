pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}
interface IFlashLoanRecipient {
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}
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
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}
interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData) external returns (int256 delta);
    function settle(address currency) external payable returns (uint256 paid);
    function take(address currency, address to, uint256 amount) external;
}
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}
interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}
interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
contract BalancerArbitrageSwapperV4 is Ownable, IFlashLoanRecipient, IUniswapV3SwapCallback, IUnlockCallback {
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
    IBalancerVault public immutable balancerVault;
    address public immutable poolManager;
    address public immutable WETH_ADDR;
    address private activePool;
    error BorrowFailed(address token, uint256 amount);
    error SlippageExceeded(uint256 received, uint256 minimum);
    error TransferFailed(string context, address token, address to, uint256 amount, uint256 balance);
    error ArbitrageUnprofitable(uint256 finalAmount, uint256 requiredAmount);
    error InsufficientProfit(uint256 actualProfit, uint256 minProfit);
    error UnsupportedPoolVersion(PoolVersion version);
    error InvalidTokenArray(string reason);
    error UnauthorizedCallback();
    error SwapFailed(uint256 swapIndex, PoolVersion version, address pool, address tokenIn, uint256 amountIn, string reason);
    error InsufficientBalance(string context, address token, uint256 required, uint256 available);
    event ArbitrageExecuted(address indexed tokenBorrowed, uint256 amountBorrowed, uint256 profit);
    event ArbitrageStarted(address indexed token, uint256 amount);
    event ArbitrageError(string reason);
    event SwapExecuted(address tokenIn, address tokenOut, address pool, uint256 amountIn, uint256 amountOut, PoolVersion version);
    event DebugBalance(string context, address token, uint256 balance);
    event DebugSwapStart(uint256 swapIndex, address tokenIn, address tokenOut, uint256 amountIn);
    struct ArbSwap {
        PoolVersion version;
        address pool;
        address tokenIn;
        address tokenOut;
        uint160 sqrtPriceLimitX96;
        uint256 amountOutMin;
        PoolKey poolKey;
        bool useNativeETH;
    }
    struct FlashLoanData {
        address originator;
        address borrowToken;
        uint256 borrowAmount;
        ArbSwap[] swaps;
        uint256 minProfit;
    }
    constructor(address _balancerVault, address _poolManager, address _weth) Ownable(msg.sender) {
        require(_balancerVault != address(0), "Invalid Balancer Vault address");
        require(_weth != address(0), "Invalid WETH address");
        balancerVault = IBalancerVault(_balancerVault);
        poolManager = _poolManager;
        WETH_ADDR = _weth;
    }
    function executeArbitrage(
        address borrowToken,
        uint256 borrowAmount,
        ArbSwap[] calldata swaps,
        uint256 minProfit
    ) external onlyOwner {
        require(swaps.length > 1, "Arbitrage requires at least two swaps");
        require(swaps[0].tokenIn == borrowToken, "First swap tokenIn must match borrowed token");
        require(swaps[swaps.length-1].tokenOut == borrowToken, "Last swap tokenOut must match borrowed token for repayment");
        emit ArbitrageStarted(borrowToken, borrowAmount);
        address[] memory tokens = new address[](1);
        tokens[0] = borrowToken;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        bytes memory userData = abi.encode(
            FlashLoanData({
                originator: msg.sender,
                borrowToken: borrowToken,
                borrowAmount: borrowAmount,
                swaps: swaps,
                minProfit: minProfit
            })
        );
        balancerVault.flashLoan(address(this), tokens, amounts, userData);
    }
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external virtual override {
        if (msg.sender != address(balancerVault)) {
            revert UnauthorizedCallback();
        }
        FlashLoanData memory data = abi.decode(userData, (FlashLoanData));
        require(tokens.length == 1, "Only single token flash loans supported");
        require(amounts.length == 1, "Only single amount flash loans supported");
        address tokenBorrowed = tokens[0];
        uint256 amountBorrowed = amounts[0];
        uint256 feeAmount = feeAmounts[0];
        require(tokenBorrowed == data.borrowToken, "Token mismatch");
        require(amountBorrowed == data.borrowAmount, "Amount mismatch");
        uint256 startBalance = IERC20(tokenBorrowed).balanceOf(address(this));
        if (startBalance < amountBorrowed) {
            revert BorrowFailed(tokenBorrowed, amountBorrowed);
        }
        uint256 finalAmount = _executeArbitrageLogic(tokenBorrowed, amountBorrowed, data.swaps);
        uint256 repayAmount = amountBorrowed + feeAmount;
        if (finalAmount < repayAmount) {
            revert ArbitrageUnprofitable(finalAmount, repayAmount);
        }
        uint256 profit = finalAmount - repayAmount;
        if (profit < data.minProfit) {
            revert InsufficientProfit(profit, data.minProfit);
        }
        uint256 balance = IERC20(tokenBorrowed).balanceOf(address(this));
        if (balance < repayAmount) {
            revert ArbitrageUnprofitable(balance, repayAmount);
        }
        if (IERC20(tokenBorrowed).allowance(address(this), address(balancerVault)) < repayAmount) {
            IERC20(tokenBorrowed).forceApprove(address(balancerVault), type(uint256).max);
        }
        emit ArbitrageExecuted(tokenBorrowed, amountBorrowed, profit);
    }
    function _executeArbitrageLogic(
        address tokenBorrowed,
        uint256 amountBorrowed,
        ArbSwap[] memory swaps
    ) internal returns (uint256 finalAmount) {
        uint256 currentAmount = amountBorrowed;
        address currentToken = tokenBorrowed;
        for (uint i = 0; i < swaps.length; i++) {
            ArbSwap memory swap = swaps[i];
            require(swap.tokenIn == currentToken, "Token mismatch in swap sequence");
            emit DebugSwapStart(i, swap.tokenIn, swap.tokenOut, currentAmount);
            emit DebugBalance("PRE_SWAP", swap.tokenIn, IERC20(swap.tokenIn).balanceOf(address(this)));
            uint256 amountOut;
            if (swap.version == PoolVersion.UniswapV2 ||
                swap.version == PoolVersion.SushiSwapV2 ||
                swap.version == PoolVersion.PancakeSwapV2) {
                amountOut = _swapV2(swap.pool, swap.tokenIn, currentAmount, swap.amountOutMin, swap.version);
            } else if (swap.version == PoolVersion.UniswapV3 ||
                       swap.version == PoolVersion.SushiSwapV3 ||
                       swap.version == PoolVersion.PancakeSwapV3) {
                amountOut = _swapV3(swap.pool, swap.tokenIn, currentAmount, swap.amountOutMin, swap.sqrtPriceLimitX96);
            } else if (swap.version == PoolVersion.UniswapV4) {
                amountOut = _swapV4(swap.pool, swap.tokenIn, currentAmount, swap.amountOutMin, swap.poolKey, swap.useNativeETH);
            } else {
                revert UnsupportedPoolVersion(swap.version);
            }
            uint256 postSwapBalance = IERC20(swap.tokenOut).balanceOf(address(this));
            emit DebugBalance("POST_SWAP", swap.tokenOut, postSwapBalance);
            emit SwapExecuted(swap.tokenIn, swap.tokenOut, swap.pool, currentAmount, amountOut, swap.version);
            currentToken = swap.tokenOut;
            currentAmount = amountOut;
        }
        require(currentToken == tokenBorrowed, "Final token must match borrowed token");
        return currentAmount;
    }
    function _calculateAmountOut(
        uint112 reserveIn,
        uint112 reserveOut,
        uint256 amountIn,
        uint256 feeBps
    ) internal pure returns (uint256) {
        uint256 feeMultiplier = 10000 - feeBps;
        uint256 amountInWithFee = amountIn * feeMultiplier;
        return (amountInWithFee * reserveOut) / (reserveIn * 10000 + amountInWithFee);
    }
    function _swapV2(
        address pool,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        PoolVersion poolVersion
    ) internal returns (uint256 amountOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        address token0 = pair.token0();
        bool isToken0 = tokenIn == token0;
        (uint112 reserveIn, uint112 reserveOut) = isToken0 ? (r0, r1) : (r1, r0);
        uint256 feeBps;
        if (poolVersion == PoolVersion.PancakeSwapV2) {
            feeBps = PANCAKESWAP_FEE;
        } else if (poolVersion == PoolVersion.SushiSwapV2) {
            feeBps = SUSHISWAP_FEE;
        } else {
            feeBps = UNISWAP_V2_FEE;
        }
        amountOut = _calculateAmountOut(reserveIn, reserveOut, amountIn, feeBps);
        if (amountOut < amountOutMin) {
            revert SlippageExceeded(amountOut, amountOutMin);
        }
        uint256 balance = IERC20(tokenIn).balanceOf(address(this));
        emit DebugBalance("V2_SWAP_PRE_TRANSFER", tokenIn, balance);
        if (balance < amountIn) {
            revert InsufficientBalance("V2_SWAP", tokenIn, amountIn, balance);
        }
        IERC20(tokenIn).safeTransfer(pool, amountIn);
        (uint amount0Out, uint amount1Out) = isToken0
            ? (uint(0), amountOut)
            : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        return amountOut;
    }
    function _swapV3(
        address pool,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96
    ) internal returns (uint256 amountOut) {
        IUniswapV3Pool v3pool = IUniswapV3Pool(pool);
        bool zeroForOne = (tokenIn == v3pool.token0());
        activePool = pool;
        (int256 amt0, int256 amt1) = v3pool.swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            abi.encode(tokenIn)
        );
        activePool = address(0);
        int256 outDelta = zeroForOne ? amt1 : amt0;
        amountOut = uint256(-outDelta);
        if (amountOut < amountOutMin) {
            revert SlippageExceeded(amountOut, amountOutMin);
        }
        return amountOut;
    }
    function _swapV4(
        address,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        PoolKey memory poolKey,
        bool useNativeETH
    ) internal returns (uint256 amountOut) {
        require(poolManager != address(0), "V4 PoolManager not set");
        bool zeroForOne;
        if (useNativeETH) {
            zeroForOne = (poolKey.currency0 == address(0)) ? (tokenIn == WETH_ADDR) : (tokenIn == poolKey.currency0);
        } else {
            zeroForOne = (tokenIn == poolKey.currency0);
        }
        bytes memory data = abi.encode(
            poolKey,
            SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: -int256(amountIn),
                sqrtPriceLimitX96: zeroForOne ? 4295128739 + 1 : 1461446703485210103287273052203988822378723970342 - 1
            }),
            tokenIn,
            useNativeETH
        );
        bytes memory result = IPoolManager(poolManager).unlock(data);
        amountOut = abi.decode(result, (uint256));
        if (amountOut < amountOutMin) {
            revert SlippageExceeded(amountOut, amountOutMin);
        }
    }
    function unlockCallback(bytes calldata data) external virtual override returns (bytes memory) {
        require(msg.sender == poolManager, "Unauthorized caller");
        (PoolKey memory key, SwapParams memory params, address tokenIn, bool useNativeETH) = abi.decode(data, (PoolKey, SwapParams, address, bool));
        int256 delta = IPoolManager(poolManager).swap(key, params, new bytes(0));
        int128 amount0 = int128(delta >> 128);
        int128 amount1 = int128(delta);
        uint256 amountOut;
        if (amount0 > 0) {
            uint256 amt = uint256(int256(amount0));
            if (useNativeETH && key.currency0 == address(0)) {
                IWETH(WETH_ADDR).withdraw(amt);
                IPoolManager(poolManager).settle{value: amt}(address(0));
            } else {
                IERC20(key.currency0).safeTransfer(msg.sender, amt);
                IPoolManager(poolManager).settle(key.currency0);
            }
        } else if (amount0 < 0) {
            uint256 takeAmount = uint256(int256(-amount0));
            IPoolManager(poolManager).take(key.currency0, address(this), takeAmount);
            if (useNativeETH && key.currency0 == address(0)) {
                IWETH(WETH_ADDR).deposit{value: takeAmount}();
            }
            if (key.currency0 != tokenIn) amountOut = takeAmount;
        }
        if (amount1 > 0) {
            uint256 amt = uint256(int256(amount1));
            if (useNativeETH && key.currency1 == address(0)) {
                IWETH(WETH_ADDR).withdraw(amt);
                IPoolManager(poolManager).settle{value: amt}(address(0));
            } else {
                IERC20(key.currency1).safeTransfer(msg.sender, amt);
                IPoolManager(poolManager).settle(key.currency1);
            }
        } else if (amount1 < 0) {
            uint256 takeAmount = uint256(int256(-amount1));
            IPoolManager(poolManager).take(key.currency1, address(this), takeAmount);
            if (useNativeETH && key.currency1 == address(0)) {
                IWETH(WETH_ADDR).deposit{value: takeAmount}();
            }
            if (key.currency1 != tokenIn) amountOut = takeAmount;
        }
        return abi.encode(amountOut);
    }
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == activePool && activePool != address(0), "Unauthorized callback");
        address tokenIn = abi.decode(data, (address));
        if (amount0Delta > 0) {
            uint256 transferAmount = uint256(amount0Delta);
            uint256 balance = IERC20(tokenIn).balanceOf(address(this));
            emit DebugBalance("V3_CALLBACK_TOKEN0", tokenIn, balance);
            if (balance < transferAmount) {
                revert InsufficientBalance("V3_CALLBACK", tokenIn, transferAmount, balance);
            }
            IERC20(tokenIn).safeTransfer(msg.sender, transferAmount);
        } else if (amount1Delta > 0) {
            uint256 transferAmount = uint256(amount1Delta);
            uint256 balance = IERC20(tokenIn).balanceOf(address(this));
            emit DebugBalance("V3_CALLBACK_TOKEN1", tokenIn, balance);
            if (balance < transferAmount) {
                revert InsufficientBalance("V3_CALLBACK", tokenIn, transferAmount, balance);
            }
            IERC20(tokenIn).safeTransfer(msg.sender, transferAmount);
        }
    }
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    receive() external payable {}
}