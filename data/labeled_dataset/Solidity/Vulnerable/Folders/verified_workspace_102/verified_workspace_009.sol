pragma solidity ^0.4.25;
import "./tokenWhitelist.sol";
import "../internals/ensResolvable.sol";
contract TokenWhitelistable is ENSResolvable {
    bytes32 private _tokenWhitelistNode;
    constructor(bytes32 _tokenWhitelistNameHash_) internal {
        _tokenWhitelistNode = _tokenWhitelistNameHash_;
    }
    function tokenWhitelistNode() external view returns (bytes32) {
        return _tokenWhitelistNode;
    }
    function _getTokenInfo(address _a) internal view returns (string, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getTokenInfo(_a);
    }
    function _getStablecoinInfo() internal view returns (string, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getStablecoinInfo();
    }
    function _tokenAddressArray() internal view returns (address[]) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).tokenAddressArray();
    }
    function _updateTokenRate(address _token, uint _rate, uint _updateDate) internal {
        ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).updateTokenRate(_token, _rate, _updateDate);
    }
    function _isTokenAvailable(address _a) internal view returns (bool) {
        ( , , , bool available, , , ) = _getTokenInfo(_a);
        return available;
    }
    function _isTokenBurnable(address _a) internal view returns (bool) {
        ( , , , , , bool burnable, ) = _getTokenInfo(_a);
        return burnable;
    }
    function _isTokenLoadable(address _a) internal view returns (bool) {
        ( , , , , bool loadable, , ) = _getTokenInfo(_a);
        return loadable;
    }
    function _stablecoin() internal view returns (address) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).stablecoin();
    }
}