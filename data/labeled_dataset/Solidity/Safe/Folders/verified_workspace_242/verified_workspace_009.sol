pragma solidity ^0.4.13;
import "./Ownable.sol";
import "./OwnableDelegateProxy.sol";
contract ProxyRegistry is Ownable {
    address public delegateProxyImplementation;
    mapping(address => OwnableDelegateProxy) public proxies;
    mapping(address => uint256) public pending;
    mapping(address => bool) public contracts;
    uint256 public DELAY_PERIOD = 2 weeks;
    function startGrantAuthentication(address addr) public onlyOwner {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }
    function endGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] &&
                pending[addr] != 0 &&
                ((pending[addr] + DELAY_PERIOD) < now)
        );
        pending[addr] = 0;
        contracts[addr] = true;
    }
    function revokeAuthentication(address addr) public onlyOwner {
        contracts[addr] = false;
    }
    function registerProxy() public returns (OwnableDelegateProxy proxy) {
        require(proxies[msg.sender] == address(0));
        proxy = new OwnableDelegateProxy(
            msg.sender,
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                msg.sender,
                address(this)
            )
        );
        proxies[msg.sender] = proxy;
        return proxy;
    }
}