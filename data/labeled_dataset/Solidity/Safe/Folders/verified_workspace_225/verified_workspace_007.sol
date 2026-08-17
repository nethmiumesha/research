pragma solidity ^0.5.4;
import "./WhitelistedWithGovernance.sol";
contract WhitelistedWithGovernanceAndChangableTimelock is WhitelistedWithGovernance {
    event Proposed(uint256 timelock);
    event Committed(uint256 timelock);
    uint256 timelockProposalTime = 0;
    uint256 proposedTimelock = 0;
    function proposeTimelock(uint256 _timelock) public onlyGovernor {
        timelockProposalTime = now;
        proposedTimelock = _timelock;
        emit Proposed(_timelock);
    }
    function commitTimelock() public onlyGovernor {
        require(timelockProposalTime != 0, "Didn't proposed yet");
        require((timelockProposalTime + TIME_LOCK_INTERVAL) < now, "Can't commit yet");
        TIME_LOCK_INTERVAL = proposedTimelock;
        emit Committed(proposedTimelock);
        timelockProposalTime = 0;
    }
}