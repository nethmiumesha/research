pragma solidity ^0.8.4;
import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
abstract contract RateLimited is CoreRef {
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;
    uint256 public rateLimitPerSecond;
    uint256 public lastBufferUsedTime;
    uint256 public bufferCap;
    bool public doPartialAction;
    uint256 private _bufferStored;
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);
    event RateLimitPerSecondUpdate(uint256 oldRateLimitPerSecond, uint256 newRateLimitPerSecond);
    constructor(uint256 _maxRateLimitPerSecond, uint256 _rateLimitPerSecond, uint256 _bufferCap, bool _doPartialAction) {
        lastBufferUsedTime = block.timestamp;
        _bufferStored = _bufferCap;
        _setBufferCap(_bufferCap);
        require(_rateLimitPerSecond <= _maxRateLimitPerSecond, "RateLimited: rateLimitPerSecond too high");
        _setRateLimitPerSecond(_rateLimitPerSecond);
        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
        doPartialAction = _doPartialAction;
    }
    function setRateLimitPerSecond(uint256 newRateLimitPerSecond) external onlyGovernorOrAdmin {
        require(newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND, "RateLimited: rateLimitPerSecond too high");
        _setRateLimitPerSecond(newRateLimitPerSecond);
    }
    function setbufferCap(uint256 newBufferCap) external onlyGovernorOrAdmin {
        _setBufferCap(newBufferCap);
    }
    function buffer() public view returns(uint256) {
        uint256 elapsed = block.timestamp - lastBufferUsedTime;
        return Math.min(_bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }
    function _depleteBuffer(uint256 amount) internal returns(uint256) {
        uint256 newBuffer = buffer();
        uint256 usedAmount = amount;
        if (doPartialAction && usedAmount > newBuffer) {
            usedAmount = newBuffer;
        }
        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(usedAmount <= newBuffer, "RateLimited: rate limit hit");
        _bufferStored = newBuffer - usedAmount;
        lastBufferUsedTime = block.timestamp;
        return usedAmount;
    }
    function _setRateLimitPerSecond(uint256 newRateLimitPerSecond) internal {
        _bufferStored = buffer();
        lastBufferUsedTime = block.timestamp;
        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;
        emit RateLimitPerSecondUpdate(oldRateLimitPerSecond, newRateLimitPerSecond);
    }
    function _setBufferCap(uint256 newBufferCap) internal {
        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;
        if (_bufferStored > newBufferCap) {
            _bufferStored = newBufferCap;
        }
        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }
}