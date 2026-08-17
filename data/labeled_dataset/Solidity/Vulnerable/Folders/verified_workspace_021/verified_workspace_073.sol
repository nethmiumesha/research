pragma solidity ^0.5.16;
import "./Owned.sol";
import "./Proxy.sol";
contract Proxyable is Owned {
    Proxy public proxy;
    address public messageSender;
    constructor(address payable _proxy) internal {
        require(owner != address(0), "Owner must be set");
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }
    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }
    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }
    modifier onlyProxy {
        _onlyProxy();
        _;
    }
    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }
    modifier optionalProxy {
        _optionalProxy();
        _;
    }
    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }
    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }
    event ProxyUpdated(address proxyAddress);
}