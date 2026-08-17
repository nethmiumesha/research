pragma solidity 0.4.25;
import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import { TimeLockUpgrade } from "./TimeLockUpgrade.sol";
import { AddressArrayUtils } from "./AddressArrayUtils.sol";
contract WhiteList is
    Ownable,
    TimeLockUpgrade
{
    using AddressArrayUtils for address[];
    address[] public addresses;
    mapping(address => bool) public whiteList;
    event AddressAdded(
        address _address
    );
    event AddressRemoved(
        address _address
    );
    constructor(
        address[] _initialAddresses
    )
        public
    {
        for (uint256 i = 0; i < _initialAddresses.length; i++) {
            address addressToAdd = _initialAddresses[i];
            addresses.push(addressToAdd);
            whiteList[addressToAdd] = true;
        }
    }
    function addAddress(
        address _address
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            !whiteList[_address],
            "WhiteList.addAddress: Address has already been whitelisted."
        );
        addresses.push(_address);
        whiteList[_address] = true;
        emit AddressAdded(
            _address
        );
    }
    function removeAddress(
        address _address
    )
        external
        onlyOwner
        timeLockUpgrade
    {
        require(
            whiteList[_address],
            "WhiteList.removeAddress: Address is not current whitelisted."
        );
        addresses = addresses.remove(_address);
        whiteList[_address] = false;
        emit AddressRemoved(
            _address
        );
    }
    function validAddresses()
        external
        view
        returns(address[])
    {
        return addresses;
    }
    function areValidAddresses(
        address[] _addresses
    )
        external
        view
        returns(bool)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!whiteList[_addresses[i]]) {
                return false;
            }
        }
        return true;
    }
}