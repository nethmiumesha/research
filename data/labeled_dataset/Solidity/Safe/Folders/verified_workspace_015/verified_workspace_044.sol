pragma solidity ^0.6.0;
import "../payment/PullPayment.sol";
contract PullPaymentMock is PullPayment {
    constructor () public payable { }
    function callTransfer(address dest, uint256 amount) public {
        _asyncTransfer(dest, amount);
    }
}