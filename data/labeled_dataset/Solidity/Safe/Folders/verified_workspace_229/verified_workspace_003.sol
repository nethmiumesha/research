pragma solidity 0.4.24;
import "./MarketSource.sol";
contract MarketSourceFactory {
    event LogSourceCreated(address owner, MarketSource source);
    function createSource(string name, uint64 reportExpirationTimeSec)
        public
        returns (MarketSource)
    {
        MarketSource source = new MarketSource(name, reportExpirationTimeSec);
        source.transferOwnership(msg.sender);
        emit LogSourceCreated(msg.sender, source);
        return source;
    }
}