pragma solidity ^0.8.33;
interface ICurvePoolPricable {
    function get_virtual_price() external view returns (uint256);
}