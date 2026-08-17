pragma solidity 0.8.7;
import "../implementation/LeveragedPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
contract TestPoolFactory {
    address public immutable poolBase;
    constructor(address _pool) {
        require(_pool != address(0));
        poolBase = _pool;
    }
    event DeployPool(address indexed pool);
    function createPool(string calldata _poolCode) external {
        LeveragedPool pool = LeveragedPool(
            Clones.cloneDeterministic(address(poolBase), keccak256(abi.encode(_poolCode)))
        );
        emit DeployPool(address(pool));
    }
}