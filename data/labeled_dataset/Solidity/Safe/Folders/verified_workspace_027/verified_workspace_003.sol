pragma solidity 0.5.8;
import "../proxy/OwnedUpgradeabilityProxy.sol";
import "./OZStorage.sol";
import "./SecurityTokenStorage.sol";
contract SecurityTokenProxy is OZStorage, SecurityTokenStorage, OwnedUpgradeabilityProxy {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string memory _tokenDetails,
        address _polymathRegistry
    )
        public
    {
        require(_polymathRegistry != address(0), "Invalid Address");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        polymathRegistry = IPolymathRegistry(_polymathRegistry);
        tokenDetails = _tokenDetails;
        granularity = _granularity;
        _owner = msg.sender;
    }
}