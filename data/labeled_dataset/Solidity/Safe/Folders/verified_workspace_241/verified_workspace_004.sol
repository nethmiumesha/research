pragma solidity 0.7.6;
interface RocketMinipoolPenaltyInterface {
    function setMaxPenaltyRate(uint256 _rate) external;
    function getMaxPenaltyRate() external view returns (uint256);
    function setPenaltyRate(address _minipoolAddress, uint256 _rate) external;
    function getPenaltyRate(address _minipoolAddress) external view returns(uint256);
}