pragma solidity ^0.8.4;
import "../refs/CoreRef.sol";
abstract contract Incentivized is CoreRef {
    uint256 public incentiveAmount;
    event IncentiveUpdate(uint256 oldIncentiveAmount, uint256 newIncentiveAmount);
    constructor(uint256 _incentiveAmount) {
        incentiveAmount = _incentiveAmount;
        emit IncentiveUpdate(0, _incentiveAmount);
    }
    function setIncentiveAmount(uint256 newIncentiveAmount) public onlyGovernor {
        uint256 oldIncentiveAmount = incentiveAmount;
        incentiveAmount = newIncentiveAmount;
        emit IncentiveUpdate(oldIncentiveAmount, newIncentiveAmount);
    }
    function _incentivize() internal ifMinterSelf {
        _mintFei(msg.sender, incentiveAmount);
    }
}