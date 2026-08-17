pragma solidity ^0.8.24;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IMorpho {
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
interface IAavePool {
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;
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
contract FlashLiquidator {
    using SafeERC20 for IERC20;
    address public immutable executor;
    address public constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint256 private _locked = 1;
    uint8 private _mode;
    struct CompactOp {
        address user;
        address debtAsset;
        address collateralAsset;
        uint256 debtToCover;
        uint256 estimatedCollateral;
        uint8 swapPath;
        uint24 feeTier1;
        uint24 feeTier2;
    }
    struct SplitLeg {
        uint24 fee;
        uint16 bps;
    }
    struct SplitOp {
        address user;
        address debtAsset;
        address collateralAsset;
        uint256 debtToCover;
        uint256 estimatedCollateral;
        uint8 numLegs;
        SplitLeg[3] legs;
    }
    event Liquidation(
        address indexed provider,
        address indexed token,
        uint256 amount,
        uint256 profit
    );
    modifier onlyExecutor() {
        require(msg.sender == executor, "NOT_EXECUTOR");
        _;
    }
    modifier nonReentrant() {
        require(_locked == 1, "LOCKED");
        _locked = 2;
        _;
        _locked = 1;
    }
    constructor(address _executor) {
        require(_executor != address(0), "ZERO_EXECUTOR");
        executor = _executor;
    }
    function executeCompact(bytes calldata data) external onlyExecutor nonReentrant {
        require(data.length == 131, "BAD_LENGTH");
        CompactOp memory op = _decodeCompactOp(data, 0);
        uint256 minProfitWeth = uint256(uint128(bytes16(data[99:115])));
        uint256 tipWei = uint256(uint128(bytes16(data[115:131])));
        _mode = 1;
        uint256 wethStart = IERC20(WETH).balanceOf(address(this));
        bytes memory cbData = abi.encode(op, minProfitWeth, tipWei, wethStart);
        IERC20(op.debtAsset).forceApprove(MORPHO, op.debtToCover);
        IMorpho(MORPHO).flashLoan(op.debtAsset, op.debtToCover, cbData);
        _mode = 0;
    }
    function executeBatchCompact(bytes calldata data) external onlyExecutor nonReentrant {
        require(data.length >= 53, "BAD_HEADER");
        address borrowToken = address(bytes20(data[0:20]));
        uint8 numOps = uint8(data[20]);
        uint256 minProfitWeth = uint256(uint128(bytes16(data[21:37])));
        uint256 tipWei = uint256(uint128(bytes16(data[37:53])));
        require(numOps > 0, "ZERO_OPS");
        require(data.length == 53 + uint256(numOps) * 79, "BAD_LENGTH");
        CompactOp[] memory ops = new CompactOp[](numOps);
        uint256 totalBorrow;
        for (uint256 i = 0; i < numOps; i++) {
            uint256 offset = 53 + i * 79;
            ops[i] = _decodeBatchOp(data, offset, borrowToken);
            totalBorrow += ops[i].debtToCover;
        }
        _mode = 2;
        uint256 wethStart = IERC20(WETH).balanceOf(address(this));
        bytes memory cbData = abi.encode(ops, minProfitWeth, tipWei, wethStart);
        IERC20(borrowToken).forceApprove(MORPHO, totalBorrow);
        IMorpho(MORPHO).flashLoan(borrowToken, totalBorrow, cbData);
        _mode = 0;
    }
    function executeSplit(bytes calldata data) external onlyExecutor nonReentrant {
        require(data.length == 140, "BAD_LENGTH");
        SplitOp memory op = _decodeSplitOp(data);
        uint256 minProfitWeth = uint256(uint128(bytes16(data[108:124])));
        uint256 tipWei = uint256(uint128(bytes16(data[124:140])));
        uint256 totalBps;
        for (uint256 i = 0; i < op.numLegs; i++) {
            totalBps += op.legs[i].bps;
        }
        require(totalBps == 10000, "BAD_BPS_SUM");
        require(op.numLegs >= 2 && op.numLegs <= 3, "BAD_NUM_LEGS");
        _mode = 3;
        uint256 wethStart = IERC20(WETH).balanceOf(address(this));
        bytes memory cbData = abi.encode(op, minProfitWeth, tipWei, wethStart);
        IERC20(op.debtAsset).forceApprove(MORPHO, op.debtToCover);
        IMorpho(MORPHO).flashLoan(op.debtAsset, op.debtToCover, cbData);
        _mode = 0;
    }
    function onMorphoFlashLoan(uint256 amount, bytes calldata data) external {
        require(msg.sender == MORPHO, "NOT_MORPHO");
        if (_mode == 1) {
            (CompactOp memory op, uint256 minProfitWeth, uint256 tipWei, uint256 wethStart) =
                abi.decode(data, (CompactOp, uint256, uint256, uint256));
            _executeLiquidation(op);
            IERC20(op.debtAsset).forceApprove(AAVE_POOL, 0);
            _settle(op.debtAsset, amount, wethStart, minProfitWeth, tipWei);
            emit Liquidation(MORPHO, op.debtAsset, op.debtToCover, 0);
        } else if (_mode == 2) {
            (CompactOp[] memory ops, uint256 minProfitWeth, uint256 tipWei, uint256 wethStart) =
                abi.decode(data, (CompactOp[], uint256, uint256, uint256));
            for (uint256 i = 0; i < ops.length; i++) {
                _executeLiquidation(ops[i]);
            }
            IERC20(ops[0].debtAsset).forceApprove(AAVE_POOL, 0);
            _settle(ops[0].debtAsset, amount, wethStart, minProfitWeth, tipWei);
            emit Liquidation(MORPHO, ops[0].debtAsset, 0, 0);
        } else if (_mode == 3) {
            (SplitOp memory op, uint256 minProfitWeth, uint256 tipWei, uint256 wethStart) =
                abi.decode(data, (SplitOp, uint256, uint256, uint256));
            _executeSplitLiquidation(op);
            IERC20(op.debtAsset).forceApprove(AAVE_POOL, 0);
            _settle(op.debtAsset, amount, wethStart, minProfitWeth, tipWei);
            emit Liquidation(MORPHO, op.debtAsset, op.debtToCover, 0);
        } else {
            revert("INVALID_MODE");
        }
    }
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        if (amount0Delta <= 0 && amount1Delta <= 0) return;
        (address tokenIn, address tokenOut, uint24 fee) =
            abi.decode(data, (address, address, uint24));
        require(msg.sender == _computePoolAddress(tokenIn, tokenOut, fee), "NOT_UNI_POOL");
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
        IERC20(tokenIn).safeTransfer(msg.sender, amountToPay);
    }
    function _executeLiquidation(CompactOp memory op) internal {
        IERC20(op.debtAsset).forceApprove(AAVE_POOL, op.debtToCover);
        uint256 debtBefore = IERC20(op.debtAsset).balanceOf(address(this));
        uint256 colBefore = (op.swapPath != 0)
            ? IERC20(op.collateralAsset).balanceOf(address(this))
            : 0;
        IAavePool(AAVE_POOL).liquidationCall(
            op.collateralAsset,
            op.debtAsset,
            op.user,
            op.debtToCover,
            false
        );
        if (op.swapPath == 0) return;
        uint256 actualDebtSpent = debtBefore - IERC20(op.debtAsset).balanceOf(address(this));
        uint256 actualColReceived = IERC20(op.collateralAsset).balanceOf(address(this)) - colBefore;
        if (op.swapPath == 1) {
            if (actualDebtSpent > 0) {
                _directSwap(WETH, op.debtAsset, op.feeTier1, -int256(actualDebtSpent));
            }
        } else if (op.swapPath == 2) {
            if (actualColReceived > 0) {
                _directSwap(op.collateralAsset, WETH, op.feeTier1, int256(actualColReceived));
            }
        } else if (op.swapPath == 3) {
            if (actualColReceived > 0) {
                _directSwap(op.collateralAsset, WETH, op.feeTier1, int256(actualColReceived));
            }
            if (actualDebtSpent > 0) {
                _directSwap(WETH, op.debtAsset, op.feeTier2, -int256(actualDebtSpent));
            }
        }
    }
    function _executeSplitLiquidation(SplitOp memory op) internal {
        IERC20(op.debtAsset).forceApprove(AAVE_POOL, op.debtToCover);
        uint256 debtBefore = IERC20(op.debtAsset).balanceOf(address(this));
        uint256 colBefore = IERC20(op.collateralAsset).balanceOf(address(this));
        IAavePool(AAVE_POOL).liquidationCall(
            op.collateralAsset,
            op.debtAsset,
            op.user,
            op.debtToCover,
            false
        );
        uint256 actualDebtSpent = debtBefore - IERC20(op.debtAsset).balanceOf(address(this));
        uint256 actualColReceived = IERC20(op.collateralAsset).balanceOf(address(this)) - colBefore;
        if (op.debtAsset == WETH) {
            if (actualColReceived > 0) {
                _executeSplitSwap(
                    op.collateralAsset, WETH,
                    op.legs, op.numLegs,
                    actualColReceived, true
                );
            }
        } else if (op.collateralAsset == WETH) {
            if (actualDebtSpent > 0) {
                _executeSplitSwap(
                    WETH, op.debtAsset,
                    op.legs, op.numLegs,
                    actualDebtSpent, false
                );
            }
        } else {
            revert("SPLIT_TWO_HOP_NOT_SUPPORTED");
        }
    }
    function _executeSplitSwap(
        address tokenIn,
        address tokenOut,
        SplitLeg[3] memory legs,
        uint8 numLegs,
        uint256 totalAmount,
        bool exactInput
    ) internal {
        uint256 spent;
        for (uint8 i = 0; i < numLegs; i++) {
            uint256 legAmount;
            if (i == numLegs - 1) {
                legAmount = totalAmount - spent;
            } else {
                legAmount = totalAmount * legs[i].bps / 10000;
                spent += legAmount;
            }
            if (legAmount == 0) continue;
            if (exactInput) {
                _directSwap(tokenIn, tokenOut, legs[i].fee, int256(legAmount));
            } else {
                _directSwap(tokenIn, tokenOut, legs[i].fee, -int256(legAmount));
            }
        }
    }
    function _directSwap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int256 amountSpecified
    ) internal {
        address pool = _computePoolAddress(tokenIn, tokenOut, fee);
        bool zeroForOne = tokenIn < tokenOut;
        IUniswapV3Pool(pool).swap(
            address(this),
            zeroForOne,
            amountSpecified,
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(tokenIn, tokenOut, fee)
        );
    }
    function _computePoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pool = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            UNISWAP_V3_FACTORY,
            keccak256(abi.encode(token0, token1, fee)),
            POOL_INIT_CODE_HASH
        )))));
    }
    function _settle(
        address debtAsset,
        uint256 amountOwed,
        uint256 wethStart,
        uint256 minProfitWeth,
        uint256 tipWei
    ) internal {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));
        uint256 reservedWeth = (debtAsset == WETH) ? amountOwed : 0;
        uint256 floor = wethStart + reservedWeth;
        require(wethBal >= floor, "UNPROFITABLE");
        uint256 freeWeth = wethBal - floor;
        require(freeWeth >= minProfitWeth + tipWei, "UNPROFITABLE");
        if (tipWei > 0) {
            IWETH(WETH).withdraw(tipWei);
            (bool sent,) = block.coinbase.call{value: tipWei}("");
            require(sent, "TIP_FAILED");
        }
        uint256 payout = freeWeth - tipWei;
        if (payout > 0) {
            IERC20(WETH).safeTransfer(executor, payout);
        }
    }
    function _decodeCompactOp(
        bytes calldata data,
        uint256 offset
    ) internal pure returns (CompactOp memory op) {
        op.user = address(bytes20(data[offset:offset + 20]));
        op.debtAsset = address(bytes20(data[offset + 20:offset + 40]));
        op.collateralAsset = address(bytes20(data[offset + 40:offset + 60]));
        op.debtToCover = uint256(uint128(bytes16(data[offset + 60:offset + 76])));
        op.estimatedCollateral = uint256(uint128(bytes16(data[offset + 76:offset + 92])));
        op.swapPath = uint8(data[offset + 92]);
        op.feeTier1 = uint24(bytes3(data[offset + 93:offset + 96]));
        op.feeTier2 = uint24(bytes3(data[offset + 96:offset + 99]));
    }
    function _decodeBatchOp(
        bytes calldata data,
        uint256 offset,
        address borrowToken
    ) internal pure returns (CompactOp memory op) {
        op.user = address(bytes20(data[offset:offset + 20]));
        op.debtAsset = borrowToken;
        op.collateralAsset = address(bytes20(data[offset + 20:offset + 40]));
        op.debtToCover = uint256(uint128(bytes16(data[offset + 40:offset + 56])));
        op.estimatedCollateral = uint256(uint128(bytes16(data[offset + 56:offset + 72])));
        op.swapPath = uint8(data[offset + 72]);
        op.feeTier1 = uint24(bytes3(data[offset + 73:offset + 76]));
        op.feeTier2 = uint24(bytes3(data[offset + 76:offset + 79]));
    }
    function _decodeSplitOp(
        bytes calldata data
    ) internal pure returns (SplitOp memory op) {
        op.user = address(bytes20(data[0:20]));
        op.debtAsset = address(bytes20(data[20:40]));
        op.collateralAsset = address(bytes20(data[40:60]));
        op.debtToCover = uint256(uint128(bytes16(data[60:76])));
        op.estimatedCollateral = uint256(uint128(bytes16(data[76:92])));
        op.numLegs = uint8(data[92]);
        op.legs[0].fee = uint24(bytes3(data[93:96]));
        op.legs[0].bps = uint16(bytes2(data[96:98]));
        op.legs[1].fee = uint24(bytes3(data[98:101]));
        op.legs[1].bps = uint16(bytes2(data[101:103]));
        op.legs[2].fee = uint24(bytes3(data[103:106]));
        op.legs[2].bps = uint16(bytes2(data[106:108]));
    }
    function withdrawToken(address token) external onlyExecutor nonReentrant {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(token).safeTransfer(executor, bal);
        }
    }
    function withdrawETH() external onlyExecutor nonReentrant {
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool sent,) = payable(executor).call{value: bal}("");
            require(sent, "ETH_SEND_FAILED");
        }
    }
    receive() external payable {}
}