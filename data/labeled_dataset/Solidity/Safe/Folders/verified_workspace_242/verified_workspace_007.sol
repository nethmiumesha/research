pragma solidity ^0.4.13;
contract OwnedUpgradeabilityStorage {
    address internal _implementation;
    address private _upgradeabilityOwner;
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }
    function implementation() public view returns (address) {
        return _implementation;
    }
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }
}