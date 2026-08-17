pragma solidity ^0.8.24;
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IProtocolFeeController } from "./IProtocolFeeController.sol";
import { IAuthorizer } from "./IAuthorizer.sol";
import { IVault } from "./IVault.sol";
interface IVaultAdmin {
    function vault() external view returns (IVault);
    function getPauseWindowEndTime() external view returns (uint32 pauseWindowEndTime);
    function getBufferPeriodDuration() external view returns (uint32 bufferPeriodDuration);
    function getBufferPeriodEndTime() external view returns (uint32 bufferPeriodEndTime);
    function getMinimumPoolTokens() external pure returns (uint256 minTokens);
    function getMaximumPoolTokens() external pure returns (uint256 maxTokens);
    function getPoolMinimumTotalSupply() external pure returns (uint256 poolMinimumTotalSupply);
    function getBufferMinimumTotalSupply() external pure returns (uint256 bufferMinimumTotalSupply);
    function getMinimumTradeAmount() external view returns (uint256 minimumTradeAmount);
    function getMinimumWrapAmount() external view returns (uint256 minimumWrapAmount);
    function isVaultPaused() external view returns (bool vaultPaused);
    function getVaultPausedState()
        external
        view
        returns (bool vaultPaused, uint32 vaultPauseWindowEndTime, uint32 vaultBufferPeriodEndTime);
    function pauseVault() external;
    function unpauseVault() external;
    function pausePool(address pool) external;
    function unpausePool(address pool) external;
    function setStaticSwapFeePercentage(address pool, uint256 swapFeePercentage) external;
    function collectAggregateFees(
        address pool
    ) external returns (uint256[] memory swapFeeAmounts, uint256[] memory yieldFeeAmounts);
    function updateAggregateSwapFeePercentage(address pool, uint256 newAggregateSwapFeePercentage) external;
    function updateAggregateYieldFeePercentage(address pool, uint256 newAggregateYieldFeePercentage) external;
    function setProtocolFeeController(IProtocolFeeController newProtocolFeeController) external;
    function enableRecoveryMode(address pool) external;
    function disableRecoveryMode(address pool) external;
    function disableQuery() external;
    function disableQueryPermanently() external;
    function enableQuery() external;
    function areBuffersPaused() external view returns (bool buffersPaused);
    function pauseVaultBuffers() external;
    function unpauseVaultBuffers() external;
    function initializeBuffer(
        IERC4626 wrappedToken,
        uint256 amountUnderlyingRaw,
        uint256 amountWrappedRaw,
        uint256 minIssuedShares,
        address sharesOwner
    ) external returns (uint256 issuedShares);
    function addLiquidityToBuffer(
        IERC4626 wrappedToken,
        uint256 maxAmountUnderlyingInRaw,
        uint256 maxAmountWrappedInRaw,
        uint256 exactSharesToIssue,
        address sharesOwner
    ) external returns (uint256 amountUnderlyingRaw, uint256 amountWrappedRaw);
    function removeLiquidityFromBuffer(
        IERC4626 wrappedToken,
        uint256 sharesToRemove,
        uint256 minAmountUnderlyingOutRaw,
        uint256 minAmountWrappedOutRaw
    ) external returns (uint256 removedUnderlyingBalanceRaw, uint256 removedWrappedBalanceRaw);
    function getBufferAsset(IERC4626 wrappedToken) external view returns (address underlyingToken);
    function getBufferOwnerShares(
        IERC4626 wrappedToken,
        address liquidityOwner
    ) external view returns (uint256 ownerShares);
    function getBufferTotalShares(IERC4626 wrappedToken) external view returns (uint256 bufferShares);
    function getBufferBalance(
        IERC4626 wrappedToken
    ) external view returns (uint256 underlyingBalanceRaw, uint256 wrappedBalanceRaw);
    function setAuthorizer(IAuthorizer newAuthorizer) external;
}