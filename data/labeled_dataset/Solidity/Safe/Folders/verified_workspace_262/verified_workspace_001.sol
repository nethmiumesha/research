pragma solidity 0.7.6;
import '../../interfaces/IAaveAddressHolder.sol';
contract AaveAddressHolder is IAaveAddressHolder {
    address public override lendingPoolAddress;
    constructor(address _lendingPoolAddress) {
        lendingPoolAddress = _lendingPoolAddress;
    }
    function setLendingPoolAddress(address newAddress) external override {
        lendingPoolAddress = newAddress;
    }
}