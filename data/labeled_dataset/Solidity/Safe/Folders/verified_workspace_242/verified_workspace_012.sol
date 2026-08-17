pragma solidity ^0.4.13;
import "./ProxyRegistry.sol";
import "./AuthenticatedProxy.sol";
contract WyvernProxyRegistry is ProxyRegistry {
    string public constant name = "Project Wyvern Proxy Registry";
    bool public initialAddressSet = false;
    constructor() public {
        delegateProxyImplementation = new AuthenticatedProxy();
    }
    function grantInitialAuthentication(address authAddress) public onlyOwner {
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[authAddress] = true;
    }
}