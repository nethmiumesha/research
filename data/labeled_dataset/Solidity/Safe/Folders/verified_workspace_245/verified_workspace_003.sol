pragma solidity 0.6.12;
import {
    AdminUpgradeabilityProxy
} from "../upgradeability/AdminUpgradeabilityProxy.sol";
contract FiatTokenProxy is AdminUpgradeabilityProxy {
    constructor(address implementationContract)
        public
        AdminUpgradeabilityProxy(implementationContract)
    {}
}