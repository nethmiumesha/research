pragma solidity 0.7.0;
interface ILendingPoolLiquidationManager {
  event LiquidationCall(address indexed collateral, address indexed principal, address indexed user, uint256 debtToCover, uint256 liquidatedCollateralAmount, address liquidator, bool receiveAToken);
  event InstrumentUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  event InstrumentUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    event FlashLoan(address _user,address _receiver,address _instrument,uint _amount,uint protocolFee,uint reserveFee,uint16 boosterID);
  function liquidationCall(address collateral, address principal, address user, uint256 debtToCover, bool receiveAToken) external returns (uint256, string memory);
}