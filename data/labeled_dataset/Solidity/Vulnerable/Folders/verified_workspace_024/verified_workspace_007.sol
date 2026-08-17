pragma solidity ^0.8.4;
abstract contract Timed {
    uint256 public startTime;
    uint256 public duration;
    event DurationUpdate(uint256 oldDuration, uint256 newDuration);
    event TimerReset(uint256 startTime);
    constructor(uint256 _duration) {
        _setDuration(_duration);
    }
    modifier duringTime() {
        require(isTimeStarted(), "Timed: time not started");
        require(!isTimeEnded(), "Timed: time ended");
        _;
    }
    modifier afterTime() {
        require(isTimeEnded(), "Timed: time not ended");
        _;
    }
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart();
    }
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0;
        }
        uint256 _duration = duration;
        uint256 timePassed = block.timestamp - startTime;
        return timePassed > _duration ? _duration : timePassed;
    }
    function isTimeStarted() public view returns (bool) {
        return startTime != 0;
    }
    function _initTimed() internal {
        startTime = block.timestamp;
        emit TimerReset(block.timestamp);
    }
    function _setDuration(uint256 newDuration) internal {
        require(newDuration != 0, "Timed: zero duration");
        uint256 oldDuration = duration;
        duration = newDuration;
        emit DurationUpdate(oldDuration, newDuration);
    }
}