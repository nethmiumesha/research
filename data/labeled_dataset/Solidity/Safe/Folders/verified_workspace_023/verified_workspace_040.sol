pragma solidity ^0.5.0;
import "../payment/PullPayment.sol";
contract PullPaymentMock is PullPayment {
    constructor () public payable {
    }
    function callTransfer(address dest, uint256 amount) public {
        _asyncTransfer(dest, amount);
    }
}