pragma solidity ^0.4.21;
import './poll/BasePoll.sol';
import './fund/IPollManagedFund.sol';
contract TapPoll is BasePoll {
    uint256 public tap;
    uint256 public minTokensPerc = 0;
    function TapPoll(
        uint256 _tap,
        address _tokenAddress,
        address _fundAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minTokensPerc
    ) public
        BasePoll(_tokenAddress, _fundAddress, _startTime, _endTime, false)
    {
        tap = _tap;
        minTokensPerc = _minTokensPerc;
    }
    function onPollFinish(bool agree) internal {
        IPollManagedFund fund = IPollManagedFund(fundAddress);
        fund.onTapPollFinish(agree, tap);
    }
    function getVotedTokensPerc() public view returns(uint256) {
        return safeDiv(safeMul(safeAdd(yesCounter, noCounter), 100), token.totalSupply());
    }
    function isSubjectApproved() internal view returns(bool) {
        return yesCounter > noCounter && getVotedTokensPerc() >= minTokensPerc;
    }
}