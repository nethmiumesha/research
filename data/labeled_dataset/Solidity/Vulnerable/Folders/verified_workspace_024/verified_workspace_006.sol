pragma solidity ^0.8.4;
import "./RateLimited.sol";
abstract contract RateLimitedMinter is RateLimited {
    uint256 private constant MAX_FEI_LIMIT_PER_SECOND = 10_000e18;
    constructor(
        uint256 _feiLimitPerSecond,
        uint256 _mintingBufferCap,
        bool _doPartialMint
    )
        RateLimited(MAX_FEI_LIMIT_PER_SECOND, _feiLimitPerSecond, _mintingBufferCap, _doPartialMint)
    {}
    function _mintFei(address to, uint256 amount) internal virtual override {
        uint256 mintAmount = _depleteBuffer(amount);
        super._mintFei(to, mintAmount);
    }
}