pragma solidity 0.5.14;
import "@openzeppelin/upgrades/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";
contract SavingAccountProxy is InitializableAdminUpgradeabilityProxy {
    function () external payable {
        if(msg.data.length == 0) return;
        super._fallback();
    }
}