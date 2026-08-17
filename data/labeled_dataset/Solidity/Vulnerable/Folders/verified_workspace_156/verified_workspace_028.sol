pragma solidity ^0.8.24;
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProtocolFeeController } from "./IProtocolFeeController.sol";
import { IAuthorizer } from "./IAuthorizer.sol";
import { IHooks } from "./IHooks.sol";
import "./VaultTypes.sol";
interface IVaultEvents {
    event PoolRegistered(
        address indexed pool,
        address indexed factory,
        TokenConfig[] tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        PoolRoleAccounts roleAccounts,
        HooksConfig hooksConfig,
        LiquidityManagement liquidityManagement
    );
    event PoolInitialized(address indexed pool);
    event Swap(
        address indexed pool,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 swapFeePercentage,
        uint256 swapFeeAmount
    );
    event Wrap(
        IERC4626 indexed wrappedToken,
        uint256 depositedUnderlying,
        uint256 mintedShares,
        bytes32 bufferBalances
    );
    event Unwrap(
        IERC4626 indexed wrappedToken,
        uint256 burnedShares,
        uint256 withdrawnUnderlying,
        bytes32 bufferBalances
    );
    event LiquidityAdded(
        address indexed pool,
        address indexed liquidityProvider,
        AddLiquidityKind indexed kind,
        uint256 totalSupply,
        uint256[] amountsAddedRaw,
        uint256[] swapFeeAmountsRaw
    );
    event LiquidityRemoved(
        address indexed pool,
        address indexed liquidityProvider,
        RemoveLiquidityKind indexed kind,
        uint256 totalSupply,
        uint256[] amountsRemovedRaw,
        uint256[] swapFeeAmountsRaw
    );
    event VaultPausedStateChanged(bool paused);
    event VaultQueriesDisabled();
    event VaultQueriesEnabled();
    event PoolPausedStateChanged(address indexed pool, bool paused);
    event SwapFeePercentageChanged(address indexed pool, uint256 swapFeePercentage);
    event PoolRecoveryModeStateChanged(address indexed pool, bool recoveryMode);
    event AggregateSwapFeePercentageChanged(address indexed pool, uint256 aggregateSwapFeePercentage);
    event AggregateYieldFeePercentageChanged(address indexed pool, uint256 aggregateYieldFeePercentage);
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);
    event ProtocolFeeControllerChanged(IProtocolFeeController indexed newProtocolFeeController);
    event LiquidityAddedToBuffer(
        IERC4626 indexed wrappedToken,
        uint256 amountUnderlying,
        uint256 amountWrapped,
        bytes32 bufferBalances
    );
    event BufferSharesMinted(IERC4626 indexed wrappedToken, address indexed to, uint256 issuedShares);
    event BufferSharesBurned(IERC4626 indexed wrappedToken, address indexed from, uint256 burnedShares);
    event LiquidityRemovedFromBuffer(
        IERC4626 indexed wrappedToken,
        uint256 amountUnderlying,
        uint256 amountWrapped,
        bytes32 bufferBalances
    );
    event VaultBuffersPausedStateChanged(bool paused);
    event VaultAuxiliary(address indexed pool, bytes32 indexed eventKey, bytes eventData);
}