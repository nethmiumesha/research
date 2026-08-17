pragma solidity 0.6.10;
import {Initializable} from "../packages/oz/upgradeability/Initializable.sol";
contract UpgradeableContractV1 is Initializable {
    address public addressBook;
    address public owner;
    function initialize(address _addressBook, address _owner) public initializer {
        addressBook = _addressBook;
        owner = _owner;
    }
    function getV1Version() external pure returns (uint256) {
        return 1;
    }
}