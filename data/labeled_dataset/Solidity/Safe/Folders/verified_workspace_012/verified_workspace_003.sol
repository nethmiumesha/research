pragma solidity 0.4.24;
import "./Escrow.sol";
contract PullPayment {
    Escrow private escrow;
    constructor() public {
        escrow = new Escrow();
    }
    function payments(address _dest) public view returns(uint256) {
        return escrow.depositsOf(_dest);
    }
    function _withdrawPayments(address _payee) internal returns(uint256) {
        uint256 payment = escrow.withdraw(_payee);
        return payment;
    }
    function _asyncTransfer(address _dest, uint256 _amount) internal {
        escrow.deposit.value(_amount)(_dest);
    }
    function _withdrawFunds(address _wallet) internal {
        escrow.beneficiaryWithdraw(_wallet);
    }
}