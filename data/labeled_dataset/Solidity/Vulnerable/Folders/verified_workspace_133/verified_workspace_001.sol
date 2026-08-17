pragma solidity ^0.8.22;
library AddressLib {
    function isContract(address account) internal view returns (bool) { return account.code.length > 0; }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool ok, ) = recipient.call{value: amount}(""); require(ok, "Transfer failed");
    }
}