pragma solidity 0.6.11;
import '../Interfaces/ITroveManager.sol';
import '../Interfaces/ISortedTroves.sol';
import '../Interfaces/IPriceFeed.sol';
import '../Dependencies/LiquityMath.sol';
contract FunctionCaller {
    ITroveManager troveManager;
    address public troveManagerAddress;
    ISortedTroves sortedTroves;
    address public sortedTrovesAddress;
    IPriceFeed priceFeed;
    address public priceFeedAddress;
    function setTroveManagerAddress(address _troveManagerAddress) external {
        troveManagerAddress = _troveManagerAddress;
        troveManager = ITroveManager(_troveManagerAddress);
    }
    function setSortedTrovesAddress(address _sortedTrovesAddress) external {
        troveManagerAddress = _sortedTrovesAddress;
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
    }
     function setPriceFeedAddress(address _priceFeedAddress) external {
        priceFeedAddress = _priceFeedAddress;
        priceFeed = IPriceFeed(_priceFeedAddress);
    }
    function troveManager_getCurrentICR(address _address, uint _price) external returns (uint) {
        return troveManager.getCurrentICR(_address, _price);
    }
    function sortedTroves_findInsertPosition(uint _ICR, uint _price, address _prevId, address _nextId) external returns (address, address) {
        return sortedTroves.findInsertPosition(_ICR, _price, _prevId, _nextId);
    }
}