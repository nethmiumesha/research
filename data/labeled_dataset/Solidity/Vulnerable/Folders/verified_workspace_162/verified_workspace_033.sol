pragma solidity ^0.8.24;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
library LibAddress {
    error ETH_TRANSFER_FAILED();
    function sendEther(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _calldata
    )
        internal
        returns (bool success_)
    {
        require(_to != address(0), ETH_TRANSFER_FAILED());
        assembly {
            success_ :=
                call(
                    _gasLimit,
                    _to,
                    _amount,
                    add(_calldata, 0x20),
                    mload(_calldata),
                    0,
                    0
                )
        }
    }
    function sendEtherAndVerify(address _to, uint256 _amount, uint256 _gasLimit) internal {
        if (_amount == 0) return;
        require(sendEther(_to, _amount, _gasLimit, ""), ETH_TRANSFER_FAILED());
    }
    function sendEtherAndVerify(address _to, uint256 _amount) internal {
        sendEtherAndVerify(_to, _amount, gasleft());
    }
    function supportsInterface(
        address _addr,
        bytes4 _interfaceId
    )
        internal
        view
        returns (bool result_)
    {
        (bool success, bytes memory data) =
            _addr.staticcall(abi.encodeCall(IERC165.supportsInterface, (_interfaceId)));
        if (success && data.length == 32) {
            result_ = abi.decode(data, (bool));
        }
    }
}