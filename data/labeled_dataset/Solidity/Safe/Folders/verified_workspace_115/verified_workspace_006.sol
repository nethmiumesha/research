pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "../GlobalAddressesProvider/IGlobalAddressesProvider.sol";
import {DataTypes} from "../../contracts/lendingProtocol/libraries/types/DataTypes.sol";
interface ILendingPool {
  event Deposit(address indexed instrument, address indexed user,uint256 amount);
  event Withdraw(address indexed instrument, address indexed user, address indexed to, uint256 amount);
  event Borrow(address indexed instrument, address user, address indexed onBehalfOf, uint256 amount, uint256 borrowRateMode, uint256 borrowRate);
  event Repay(address indexed instrument, address indexed user, address indexed repayer, uint256 loanRepaid, uint256 totalFeeRepaid);
  event Swap(address indexed instrument, address indexed user, uint256 rateMode);
  event InstrumentUsedAsCollateralEnabled(address indexed instrument, address indexed user);
  event InstrumentUsedAsCollateralDisabled(address indexed instrument, address indexed user);
  event RebalanceStableBorrowRate(address indexed instrument, address indexed user);
  event FlashLoan(address indexed target, address indexed initiator, address indexed asset, uint256 amount, uint256 premium, uint16 boosterID );
  event Paused();
  event Unpaused();
  event LiquidationCall(address indexed collateralAsset, address indexed debtAsset, address indexed user, uint256 debtToCover, uint256 liquidatedCollateralAmount, address liquidator, bool receiveIToken);
  event InstrumentDataUpdated(address indexed instrument, uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex);
  event depositFeeDeducted(address instrumentAddress, address user, uint amount, uint256 platformFee, uint256 reserveFee, uint16 _boosterId);
  event borrowFeeUpdated(address instrumentAddress, address user, uint256 amount, uint256 platformFee, uint256 reserveFee, uint16 _boosterId);
  event feeRepaid(address instrumentAddress, address user, address onBehalfOf, uint256 amount, uint256 platformFeePay, uint256 reserveFeePay);
  function refreshConfig() external;
  function deposit(address asset, uint256 amount, uint16 boosterID) external;
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
  function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 boosterID, address onBehalfOf) external;
  function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
  function swapBorrowRateMode(address asset, uint256 rateMode) external;
  function rebalanceStableBorrowRate(address asset, address user) external;
  function setUserUseInstrumentAsCollateral(address asset, bool useAsCollateral) external;
  function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveIToken) external;
  function flashLoan( address receiverAddress, address asset, uint256 amount, bytes calldata _params, uint16 boosterId) external;
  function getUserAccountData(address user) external view returns (
      uint256 totalCollateralUSD,
      uint256 totalDebtUSD,
      uint256 availableBorrowsUSD,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
  function getInstrumentConfiguration(address asset) external view returns ( DataTypes.InstrumentConfigurationMap memory );
  function initInstrument(address asset,address iTokenAddress, address stableDebtAddress, address variableDebtAddress, address interestRateStrategyAddress) external;
  function setInstrumentInterestRateStrategyAddress(address instrument, address rateStrategyAddress) external;
  function setConfiguration(address instrument, uint256 configuration) external;
  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);
  function getInstrumentNormalizedIncome(address asset) external view returns (uint256);
  function getInstrumentNormalizedVariableDebt(address asset) external view returns (uint256);
  function getInstrumentData(address asset) external view returns (DataTypes.InstrumentData memory);
  function finalizeTransfer(address asset, address from, address to, uint256 amount, uint256 balanceFromAfter, uint256 balanceToBefore) external;
  function getInstrumentsList() external view returns (address[] memory);
  function setPause(bool val) external;
}