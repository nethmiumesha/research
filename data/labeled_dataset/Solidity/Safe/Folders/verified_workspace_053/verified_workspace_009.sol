pragma solidity 0.6.12;
import "../token/interfaces/IERC20Token.sol";
contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
    }
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
    }
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}