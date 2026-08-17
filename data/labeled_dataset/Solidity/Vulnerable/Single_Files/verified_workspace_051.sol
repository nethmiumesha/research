pragma solidity ^0.8.19;
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}
interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract SuperbotV1 {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint160 internal constant MIN_SQRT_RATIO = 4295128740;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;
    uint256 internal constant BPS = 10_000;
    address public immutable owner;
    address private _cbTokenIn;
    struct Leg {
        address pool;
        address tokenIn;
        address tokenOut;
        uint24  fee;
        bool    isV3;
        bool    zeroForOne;
        uint256 amountIn;
    }
    event Executed(uint256 profit, uint256 bribePaid);
    event Withdrawn(address indexed token, uint256 amount);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "SuperbotV1: not owner");
        _;
    }
    function execute(
        Leg[] calldata legs,
        uint256 minProfit,
        uint256 bribeBps
    ) external onlyOwner {
        require(legs.length >= 2 && legs.length <= 12, "SuperbotV1: invalid leg count");
        uint256 wethBefore = IWETH(WETH).balanceOf(address(this));
        uint256 legCount = legs.length;
        for (uint256 i = 0; i < legCount; ) {
            Leg calldata leg = legs[i];
            uint256 amtIn = leg.amountIn;
            if (amtIn == 0) {
                amtIn = IERC20Min(leg.tokenIn).balanceOf(address(this));
            }
            if (leg.isV3) {
                _swapV3(leg, amtIn);
            } else {
                _swapV2(leg, amtIn);
            }
            unchecked { ++i; }
        }
        uint256 wethAfter  = IWETH(WETH).balanceOf(address(this));
        uint256 profit = wethAfter - wethBefore;
        require(profit >= minProfit, "SuperbotV1: profit below minimum");
        uint256 bribe = (profit * bribeBps) / BPS;
        if (bribe > 0) {
            IWETH(WETH).withdraw(bribe);
            assembly {
                if iszero(call(gas(), coinbase(), bribe, 0, 0, 0, 0)) {
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                    mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000015)
                    mstore(0x44, 0x5375706572626f7456313a206272696265207866720000000000000000000000)
                    revert(0x00, 0x64)
                }
            }
        }
        emit Executed(profit - bribe, bribe);
    }
    function _swapV2(Leg calldata leg, uint256 amtIn) internal {
        IUniswapV2Pair pool = IUniswapV2Pair(leg.pool);
        address token0 = pool.token0();
        bool tokenInIsToken0 = (leg.tokenIn == token0);
        (uint112 reserve0, uint112 reserve1, ) = pool.getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        if (tokenInIsToken0) {
            reserveIn  = uint256(reserve0);
            reserveOut = uint256(reserve1);
        } else {
            reserveIn  = uint256(reserve1);
            reserveOut = uint256(reserve0);
        }
        uint256 amountInWithFee = amtIn * 997;
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        require(amountOut > 0, "SuperbotV1: V2 zero output");
        _safeTransfer(leg.tokenIn, leg.pool, amtIn);
        if (tokenInIsToken0) {
            pool.swap(0, amountOut, address(this), new bytes(0));
        } else {
            pool.swap(amountOut, 0, address(this), new bytes(0));
        }
    }
    function _swapV3(Leg calldata leg, uint256 amtIn) internal {
        _cbTokenIn = leg.tokenIn;
        _ensureApproval(leg.tokenIn, leg.pool);
        uint160 sqrtPriceLimit = leg.zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO;
        IUniswapV3Pool(leg.pool).swap(
            address(this),
            leg.zeroForOne,
            int256(amtIn),
            sqrtPriceLimit,
            abi.encode(leg.pool)
        );
    }
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        address expectedPool = abi.decode(data, (address));
        require(msg.sender == expectedPool, "SuperbotV1: invalid V3 callback");
        uint256 amountOwed;
        if (amount0Delta > 0) {
            amountOwed = uint256(amount0Delta);
        } else {
            require(amount1Delta > 0, "SuperbotV1: both deltas non-positive");
            amountOwed = uint256(amount1Delta);
        }
        _safeTransfer(_cbTokenIn, msg.sender, amountOwed);
    }
    function withdraw(address token) external onlyOwner {
        uint256 bal = IERC20Min(token).balanceOf(address(this));
        require(bal > 0, "SuperbotV1: zero balance");
        _safeTransfer(token, owner, bal);
        emit Withdrawn(token, bal);
    }
    function withdrawETH() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "SuperbotV1: zero ETH balance");
        assembly {
            if iszero(call(gas(), caller(), bal, 0, 0, 0, 0)) {
                revert(0, 0)
            }
        }
        emit Withdrawn(address(0), bal);
    }
    receive() external payable {
        if (msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
        }
    }
    function _safeTransfer(address token, address to, uint256 amount) private {
        (bool success, bytes memory ret) = token.call(
            abi.encodeWithSelector(IERC20Min.transfer.selector, to, amount)
        );
        require(
            success && (ret.length == 0 || abi.decode(ret, (bool))),
            "SuperbotV1: token transfer failed"
        );
    }
    function _ensureApproval(address token, address spender) private {
        (bool ok, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("allowance(address,address)", address(this), spender)
        );
        if (ok && data.length >= 32) {
            uint256 allowance = abi.decode(data, (uint256));
            if (allowance >= type(uint256).max / 2) return;
        }
        (bool success, bytes memory ret) = token.call(
            abi.encodeWithSelector(IERC20Min.approve.selector, spender, type(uint256).max)
        );
        require(
            success && (ret.length == 0 || abi.decode(ret, (bool))),
            "SuperbotV1: token approve failed"
        );
    }
}