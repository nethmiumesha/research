pragma solidity ^0.8.24;
interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function coins(uint256 i) external view returns (address);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
interface ICurvePoolV2 {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth, address receiver) external returns (uint256);
}
interface ICurveMetapool {
    function underlying_coins(uint256 i) external view returns (address);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
}