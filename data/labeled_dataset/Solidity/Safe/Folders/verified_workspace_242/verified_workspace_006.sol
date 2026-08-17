pragma solidity ^0.4.13;
import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    event Upgraded(address indexed implementation);
    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation);
        _implementation = implementation;
        emit Upgraded(implementation);
    }
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }
    function upgradeToAndCall(address implementation, bytes data)
        public
        payable
        onlyProxyOwner
    {
        upgradeTo(implementation);
        require(address(this).delegatecall(data));
    }
}