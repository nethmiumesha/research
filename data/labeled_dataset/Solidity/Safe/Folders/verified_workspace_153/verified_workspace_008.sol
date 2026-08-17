pragma solidity ^0.4.21;
import './poll/BasePoll.sol';
import './fund/IPollManagedFund.sol';
contract RefundPoll is BasePoll {
    uint256 public holdEndTime = 0;
    function RefundPoll(
        address _tokenAddress,
        address _fundAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _holdEndTime,
        bool _checkTransfersAfterEnd
    ) public
        BasePoll(_tokenAddress, _fundAddress, _startTime, _endTime, _checkTransfersAfterEnd)
    {
        holdEndTime = _holdEndTime;
    }
    function tryToFinalize() public returns(bool) {
        if(holdEndTime > 0 && holdEndTime > endTime) {
            require(now >= holdEndTime);
        } else {
            require(now >= endTime);
        }
        finalized = true;
        onPollFinish(isSubjectApproved());
        return true;
    }
    function isSubjectApproved() internal view returns(bool) {
        return yesCounter > noCounter && yesCounter >= safeDiv(token.totalSupply(), 3);
    }
    function onPollFinish(bool agree) internal {
        IPollManagedFund fund = IPollManagedFund(fundAddress);
        fund.onRefundPollFinish(agree);
    }
}