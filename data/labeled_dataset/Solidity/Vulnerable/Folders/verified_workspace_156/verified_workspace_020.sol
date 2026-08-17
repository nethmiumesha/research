pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "./IVault.sol";
interface IProtocolFeeController {
    event GlobalProtocolSwapFeePercentageChanged(uint256 swapFeePercentage);
    event GlobalProtocolYieldFeePercentageChanged(uint256 yieldFeePercentage);
    event ProtocolSwapFeePercentageChanged(address indexed pool, uint256 swapFeePercentage);
    event ProtocolYieldFeePercentageChanged(address indexed pool, uint256 yieldFeePercentage);
    event PoolCreatorSwapFeePercentageChanged(address indexed pool, uint256 poolCreatorSwapFeePercentage);
    event PoolCreatorYieldFeePercentageChanged(address indexed pool, uint256 poolCreatorYieldFeePercentage);
    event ProtocolSwapFeeCollected(address indexed pool, IERC20 indexed token, uint256 amount);
    event ProtocolYieldFeeCollected(address indexed pool, IERC20 indexed token, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed pool, IERC20 indexed token, address indexed recipient, uint256 amount);
    event PoolCreatorFeesWithdrawn(
        address indexed pool,
        IERC20 indexed token,
        address indexed recipient,
        uint256 amount
    );
    event InitialPoolAggregateSwapFeePercentage(
        address indexed pool,
        uint256 aggregateSwapFeePercentage,
        bool isProtocolFeeExempt
    );
    event InitialPoolAggregateYieldFeePercentage(
        address indexed pool,
        uint256 aggregateYieldFeePercentage,
        bool isProtocolFeeExempt
    );
    event PoolRegisteredWithFeeController(address indexed pool, address indexed poolCreator, bool protocolFeeExempt);
    error ProtocolSwapFeePercentageTooHigh();
    error ProtocolYieldFeePercentageTooHigh();
    error PoolCreatorNotRegistered(address pool);
    error CallerIsNotPoolCreator(address caller, address pool);
    error PoolCreatorFeePercentageTooHigh();
    function vault() external view returns (IVault);
    function collectAggregateFees(address pool) external;
    function getGlobalProtocolSwapFeePercentage() external view returns (uint256 protocolSwapFeePercentage);
    function getGlobalProtocolYieldFeePercentage() external view returns (uint256 protocolYieldFeePercentage);
    function isPoolRegistered(address pool) external view returns (bool);
    function getPoolProtocolSwapFeeInfo(
        address pool
    ) external view returns (uint256 protocolSwapFeePercentage, bool isOverride);
    function getPoolProtocolYieldFeeInfo(
        address pool
    ) external view returns (uint256 protocolYieldFeePercentage, bool isOverride);
    function getPoolCreatorSwapFeePercentage(address pool) external view returns (uint256);
    function getPoolCreatorYieldFeePercentage(address pool) external view returns (uint256);
    function getProtocolFeeAmounts(address pool) external view returns (uint256[] memory feeAmounts);
    function getPoolCreatorFeeAmounts(address pool) external view returns (uint256[] memory feeAmounts);
    function computeAggregateFeePercentage(
        uint256 protocolFeePercentage,
        uint256 poolCreatorFeePercentage
    ) external pure returns (uint256 aggregateFeePercentage);
    function updateProtocolSwapFeePercentage(address pool) external;
    function updateProtocolYieldFeePercentage(address pool) external;
    function registerPool(
        address pool,
        address poolCreator,
        bool protocolFeeExempt
    ) external returns (uint256 aggregateSwapFeePercentage, uint256 aggregateYieldFeePercentage);
    function setGlobalProtocolSwapFeePercentage(uint256 newProtocolSwapFeePercentage) external;
    function setGlobalProtocolYieldFeePercentage(uint256 newProtocolYieldFeePercentage) external;
    function setProtocolSwapFeePercentage(address pool, uint256 newProtocolSwapFeePercentage) external;
    function setProtocolYieldFeePercentage(address pool, uint256 newProtocolYieldFeePercentage) external;
    function setPoolCreatorSwapFeePercentage(address pool, uint256 poolCreatorSwapFeePercentage) external;
    function setPoolCreatorYieldFeePercentage(address pool, uint256 poolCreatorYieldFeePercentage) external;
    function withdrawProtocolFees(address pool, address recipient) external;
    function withdrawProtocolFeesForToken(address pool, address recipient, IERC20 token) external;
    function withdrawPoolCreatorFees(address pool, address recipient) external;
    function withdrawPoolCreatorFees(address pool) external;
}