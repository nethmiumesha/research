pragma solidity ^0.8.0;
import "../UserProxy.sol";
import "../interfaces/IWETH.sol";
contract TestUserProxy is UserProxy {
    constructor(
        address _weth,
        address _trancheFactory,
        bytes32 _trancheBytecodeHash
    ) UserProxy(IWETH(_weth), _trancheFactory, _trancheBytecodeHash) {}
    function deriveTranche(address position, uint256 expiration)
        public
        view
        returns (ITranche)
    {
        return _deriveTranche(position, expiration);
    }
}