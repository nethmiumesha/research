pragma solidity 0.7.5;
import "../interfaces/IUpgradeabilityOwnerStorage.sol";
contract Upgradeable {
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
        _;
    }
}