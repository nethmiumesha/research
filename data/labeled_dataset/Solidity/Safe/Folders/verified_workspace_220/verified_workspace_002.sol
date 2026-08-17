pragma solidity ^0.5.0;
import "../common/SecuredTokenTransfer.sol";
import "./DelegateConstructorProxy.sol";
contract PayingProxy is DelegateConstructorProxy, SecuredTokenTransfer {
    constructor(address _masterCopy, bytes memory initializer, address payable funder, address paymentToken, uint256 payment)
        DelegateConstructorProxy(_masterCopy, initializer)
        public
    {
        if (payment > 0) {
            if (paymentToken == address(0)) {
                require(funder.send(payment), "Could not pay safe creation with ether");
            } else {
                require(transferToken(paymentToken, funder, payment), "Could not pay safe creation with token");
            }
        }
    }
}