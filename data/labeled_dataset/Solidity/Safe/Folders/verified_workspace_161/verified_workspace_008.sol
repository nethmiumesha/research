pragma solidity 0.6.10;
import {UpgradeableContractV1} from "./UpgradeableContractV1.sol";
contract UpgradeableContractV2 is UpgradeableContractV1 {
    function getV2Version() external pure returns (uint256) {
        return 2;
    }
}