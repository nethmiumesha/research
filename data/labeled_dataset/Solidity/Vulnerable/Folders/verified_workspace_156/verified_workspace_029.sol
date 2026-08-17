pragma solidity ^0.8.24;
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAuthorizer } from "./IAuthorizer.sol";
import { IProtocolFeeController } from "./IProtocolFeeController.sol";
import { IVault } from "./IVault.sol";
import { IHooks } from "./IHooks.sol";
import "./VaultTypes.sol";
interface IVaultExtension {
    function vault() external view returns (IVault);
    function getVaultAdmin() external view returns (address vaultAdmin);
    function isUnlocked() external view returns (bool unlocked);
    function getNonzeroDeltaCount() external view returns (uint256 nonzeroDeltaCount);
    function getTokenDelta(IERC20 token) external view returns (int256 tokenDelta);
    function getReservesOf(IERC20 token) external view returns (uint256 reserveAmount);
    function getAddLiquidityCalledFlag(address pool) external view returns (bool liquidityAdded);
    function registerPool(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts calldata roleAccounts,
        address poolHooksContract,
        LiquidityManagement calldata liquidityManagement
    ) external;
    function isPoolRegistered(address pool) external view returns (bool registered);
    function initialize(
        address pool,
        address to,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bytes memory userData
    ) external returns (uint256 bptAmountOut);
    function isPoolInitialized(address pool) external view returns (bool initialized);
    function getPoolTokens(address pool) external view returns (IERC20[] memory tokens);
    function getPoolTokenRates(
        address pool
    ) external view returns (uint256[] memory decimalScalingFactors, uint256[] memory tokenRates);
    function getPoolData(address pool) external view returns (PoolData memory poolData);
    function getPoolTokenInfo(
        address pool
    )
        external
        view
        returns (
            IERC20[] memory tokens,
            TokenInfo[] memory tokenInfo,
            uint256[] memory balancesRaw,
            uint256[] memory lastBalancesLiveScaled18
        );
    function getCurrentLiveBalances(address pool) external view returns (uint256[] memory balancesLiveScaled18);
    function getPoolConfig(address pool) external view returns (PoolConfig memory poolConfig);
    function getHooksConfig(address pool) external view returns (HooksConfig memory hooksConfig);
    function getBptRate(address pool) external view returns (uint256 rate);
    function totalSupply(address token) external view returns (uint256 tokenTotalSupply);
    function balanceOf(address token, address account) external view returns (uint256 tokenBalance);
    function allowance(address token, address owner, address spender) external view returns (uint256 tokenAllowance);
    function approve(address owner, address spender, uint256 amount) external returns (bool success);
    function isPoolPaused(address pool) external view returns (bool poolPaused);
    function getPoolPausedState(
        address pool
    )
        external
        view
        returns (bool poolPaused, uint32 poolPauseWindowEndTime, uint32 poolBufferPeriodEndTime, address pauseManager);
    function isERC4626BufferInitialized(IERC4626 wrappedToken) external view returns (bool isBufferInitialized);
    function getERC4626BufferAsset(IERC4626 wrappedToken) external view returns (address asset);
    function getAggregateSwapFeeAmount(address pool, IERC20 token) external view returns (uint256 swapFeeAmount);
    function getAggregateYieldFeeAmount(address pool, IERC20 token) external view returns (uint256 yieldFeeAmount);
    function getStaticSwapFeePercentage(address pool) external view returns (uint256 swapFeePercentage);
    function getPoolRoleAccounts(address pool) external view returns (PoolRoleAccounts memory roleAccounts);
    function computeDynamicSwapFeePercentage(
        address pool,
        PoolSwapParams memory swapParams
    ) external view returns (uint256 dynamicSwapFeePercentage);
    function getProtocolFeeController() external view returns (IProtocolFeeController protocolFeeController);
    function isPoolInRecoveryMode(address pool) external view returns (bool inRecoveryMode);
    function removeLiquidityRecovery(
        address pool,
        address from,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut
    ) external returns (uint256[] memory amountsOut);
    function quote(bytes calldata data) external returns (bytes memory result);
    function quoteAndRevert(bytes calldata data) external;
    function isQueryDisabled() external view returns (bool queryDisabled);
    function isQueryDisabledPermanently() external view returns (bool queryDisabledPermanently);
    function emitAuxiliaryEvent(bytes32 eventKey, bytes calldata eventData) external;
    function getAuthorizer() external view returns (IAuthorizer authorizer);
}