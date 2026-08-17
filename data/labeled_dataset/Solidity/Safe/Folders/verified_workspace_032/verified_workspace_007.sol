pragma solidity ^0.7.0;
import "../auth/AdminAuth.sol";
contract FeeRecipient is AdminAuth {
    address public wallet;
    constructor(address _newWallet) {
        wallet = _newWallet;
    }
    function getFeeAddr() public view returns (address) {
        return wallet;
    }
    function changeWalletAddr(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }
}