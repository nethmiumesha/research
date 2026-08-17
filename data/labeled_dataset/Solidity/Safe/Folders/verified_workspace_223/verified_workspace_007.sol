pragma solidity 0.8.7;
interface IPoolKeeper {
    event PoolAdded(address indexed poolAddress, int256 indexed firstPrice);
    event UpkeepSuccessful(address indexed pool, bytes data, int256 indexed startPrice, int256 indexed endPrice);
    event KeeperPaid(address indexed _pool, address indexed keeper, uint256 reward);
    event KeeperPaymentError(address indexed _pool, address indexed keeper, uint256 expectedReward);
    event PoolUpkeepError(address indexed pool, string reason);
    function newPool(address _poolAddress) external;
    function setFactory(address _factory) external;
    function checkUpkeepSinglePool(address pool) external view returns (bool);
    function checkUpkeepMultiplePools(address[] calldata pools) external view returns (bool);
    function performUpkeepSinglePool(address pool) external;
    function performUpkeepMultiplePools(address[] calldata pools) external;
}