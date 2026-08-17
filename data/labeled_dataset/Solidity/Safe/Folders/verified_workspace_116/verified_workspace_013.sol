pragma solidity 0.7.0;
interface ISIGHVolatilityHarvesterLendingPool {
    function addInstrument( address _instrument, address _iTokenAddress,address _stableDebtToken,address _variableDebtToken, address _sighStreamAddress, uint8 _decimals ) external returns (bool);
    function updateSIGHSupplyIndex(address currentInstrument) external  returns (bool);
    function updateSIGHBorrowIndex(address currentInstrument) external  returns (bool);
}