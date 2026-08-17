pragma solidity 0.7.6;
interface RocketMinipoolStatusInterface {
    function submitMinipoolWithdrawable(address _minipoolAddress) external;
    function executeMinipoolWithdrawable(address _minipoolAddress) external;
}