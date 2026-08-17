pragma solidity ^0.8.0;
interface IVaultManager {
    function stablecoin() external view returns (address);
    function factory() external view returns (address);
    function feeTo() external view returns (address);
    function dividend() external view returns (address);
    function treasury() external view returns (address);
    function liquidator() external view returns (address);
    function desiredSupply() external view returns (uint256);
    function rebaseActive() external view returns (bool);
    function getCDPConfig(address collateral) external view returns (uint, uint, uint, uint, bool);
    function getCDecimal(address collateral) external view returns(uint);
    function getMCR(address collateral) external view returns(uint);
    function getLFR(address collateral) external view returns(uint);
    function getSFR(address collateral) external view returns(uint);
    function getOpen(address collateral_) external view returns (bool);
    function getAssetPrice(address asset) external returns (uint);
    function getAssetValue(address asset, uint256 amount) external returns (uint256);
    function isValidCDP(address collateral, address debt, uint256 cAmount, uint256 dAmount) external returns (bool);
    function isValidSupply(uint256 issueAmount_) external returns (bool);
    function createCDP(address collateral_, uint cAmount_, uint dAmount_) external returns (bool success);
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}