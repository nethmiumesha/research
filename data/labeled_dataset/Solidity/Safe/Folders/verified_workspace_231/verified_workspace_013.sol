pragma solidity 0.7.6;
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
contract VaultFactoryProxy is TransparentUpgradeableProxy {
    constructor(address _implementation, address _admin)
        public
        TransparentUpgradeableProxy(_implementation, _admin, "")
    {}
}