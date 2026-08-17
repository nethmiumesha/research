pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./SafeMath32.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
abstract contract Timed {
    using SafeCast for uint;
	using SafeMath32 for uint32;
    uint32 public startTime;
	uint32 public duration;
    constructor(uint32 _duration) public {
        duration = _duration;
    }
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }
    function remainingTime() public view returns (uint32) {
        return duration.sub(timestamp());
    }
    function timestamp() public view returns (uint32) {
		uint32 d = duration;
		uint32 t = now.toUint32().sub(startTime);
		return t > d ? d : t;
    }
    function _initTimed() internal {
        startTime = now.toUint32();
    }
}