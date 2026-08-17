pragma solidity 0.8.6;
import "@yield-protocol/utils-v2/contracts/utils/RevertMsgExtractor.sol";
contract PoolRouterMock  {
    mapping(address => mapping(address => address)) public pools;
    function addPool(address base, address fyToken, address pool)
        external
    {
        pools[base][fyToken] = pool;
    }
    function route(address base, address fyToken, bytes memory data)
        external payable
        returns (bool success, bytes memory result)
    {
        (success, result) = pools[base][fyToken].call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }
}