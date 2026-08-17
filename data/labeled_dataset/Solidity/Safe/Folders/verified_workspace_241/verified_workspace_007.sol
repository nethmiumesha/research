pragma solidity 0.7.6;
interface RocketDAOProtocolSettingsNodeInterface {
    function getRegistrationEnabled() external view returns (bool);
    function getDepositEnabled() external view returns (bool);
    function getMinimumPerMinipoolStake() external view returns (uint256);
    function getMaximumPerMinipoolStake() external view returns (uint256);
}