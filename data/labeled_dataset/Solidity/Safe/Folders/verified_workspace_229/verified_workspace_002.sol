pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract MarketSource is Destructible {
    using SafeMath for uint256;
    event LogExchangeRateReported(
        uint128 exchangeRate,
        uint128 volume24hrs,
        uint64 indexed timestampSec
    );
    string public _name;
    uint128 private _exchangeRate;
    uint128 private _volume24hrs;
    uint64 private _timestampSec;
    uint64 public _reportExpirationTimeSec;
    constructor(string name, uint64 reportExpirationTimeSec) public {
        _name = name;
        _reportExpirationTimeSec = reportExpirationTimeSec;
    }
    function reportRate(uint128 exchangeRate, uint128 volume24hrs, uint64 timestampSec)
        external
        onlyOwner
    {
        require(exchangeRate > 0);
        require(volume24hrs > 0);
        _exchangeRate = exchangeRate;
        _volume24hrs = volume24hrs;
        _timestampSec = timestampSec;
        emit LogExchangeRateReported(exchangeRate, volume24hrs, timestampSec);
    }
    function getReport()
        public
        view
        returns (bool, uint256, uint256)
    {
        bool isFresh = (uint256(_timestampSec).add(_reportExpirationTimeSec) > now);
        return (
            isFresh,
            uint256(_exchangeRate),
            uint256(_volume24hrs)
        );
    }
}