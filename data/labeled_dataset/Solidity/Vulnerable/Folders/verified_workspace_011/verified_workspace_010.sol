pragma solidity ^0.8.7;
import "./IERC721.sol";
import "./IFeeManager.sol";
import "./IOracle.sol";
import "./IAccessControl.sol";
interface IPerpetualManagerFront is IERC721Metadata {
    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);
    function closePerpetual(
        uint256 perpetualID,
        address to,
        uint256 minCashOutAmount
    ) external;
    function addToPerpetual(uint256 perpetualID, uint256 amount) external;
    function removeFromPerpetual(
        uint256 perpetualID,
        uint256 amount,
        address to
    ) external;
    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;
    function forceClosePerpetuals(uint256[] memory perpetualIDs) external;
    function getCashOutAmount(uint256 perpetualID, uint256 rate) external view returns (uint256, uint256);
    function isApprovedOrOwner(address spender, uint256 perpetualID) external view returns (bool);
}
interface IPerpetualManagerFunctions is IAccessControl {
    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IFeeManager feeManager,
        IOracle oracle_
    ) external;
    function setFeeManager(IFeeManager feeManager_) external;
    function setHAFees(
        uint64[] memory _xHAFees,
        uint64[] memory _yHAFees,
        uint8 deposit
    ) external;
    function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external;
    function setKeeperFeesLiquidationRatio(uint64 _keeperFeesLiquidationRatio) external;
    function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external;
    function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external;
    function setLockTime(uint64 _lockTime) external;
    function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external;
    function pause() external;
    function unpause() external;
    function setFeeKeeper(uint64 feeDeposit, uint64 feesWithdraw) external;
    function setOracle(IOracle _oracle) external;
}
interface IPerpetualManager is IPerpetualManagerFunctions {
    function poolManager() external view returns (address);
    function oracle() external view returns (address);
    function targetHAHedge() external view returns (uint64);
    function totalHedgeAmount() external view returns (uint256);
}