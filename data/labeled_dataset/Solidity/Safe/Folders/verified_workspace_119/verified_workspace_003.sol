pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.0;
pragma solidity ^0.8.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
pragma solidity ^0.8.0;
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
pragma solidity 0.8.9;
interface IFeeKafra {
    function MAX_FEE() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
    function treasuryFeeWithdraw() external view returns (uint256);
    function kswFeeWithdraw() external view returns (uint256);
    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);
    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;
}
pragma solidity 0.8.9;
contract FeeKafra is Ownable, IFeeKafra {
    using SafeERC20 for IERC20;
    uint256 public constant override MAX_FEE = 10000;
    uint256 public constant MAX_WITHDRAW_FEE = 1000;
    uint256 public override withdrawFee = 200;
    uint256 public override treasuryFeeWithdraw = 5000;
    uint256 public override kswFeeWithdraw = 5000;
    uint256 public withdrawFeeSum = 10000;
    address public kswFeeRecipient;
    address public treasuryFeeRecipient;
    event SetWithdrawFee(uint256 fee);
    event SetTreasuryFeeWithdraw(uint256 fee);
    event SetKSWFeeWithdraw(uint256 fee);
    event SetKSWFeeRecipient(address to);
    event SetTreasuryFeeRecipient(address to);
    constructor(address _kswFeeRecipient, address _treasuryFeeRecipient) {
        kswFeeRecipient = _kswFeeRecipient;
        treasuryFeeRecipient = _treasuryFeeRecipient;
    }
    function calculateWithdrawFee(uint256 _wantAmount, address) external view override returns (uint256) {
        return (_wantAmount * withdrawFee) / MAX_FEE;
    }
    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_WITHDRAW_FEE, "!cap");
        withdrawFee = _fee;
        emit SetWithdrawFee(_fee);
    }
    function setTreasuryFeeWithdraw(uint256 _fee) external onlyOwner {
        treasuryFeeWithdraw = _fee;
        withdrawFeeSum = treasuryFeeWithdraw + kswFeeWithdraw;
        emit SetTreasuryFeeWithdraw(_fee);
    }
    function setKSWFeeWithdraw(uint256 _fee) external onlyOwner {
        kswFeeWithdraw = _fee;
        withdrawFeeSum = treasuryFeeWithdraw + kswFeeWithdraw;
        emit SetKSWFeeWithdraw(_fee);
    }
    function setKSWFeeRecipient(address _to) external onlyOwner {
        kswFeeRecipient = _to;
        emit SetKSWFeeRecipient(_to);
    }
    function setTreasuryFeeRecipient(address _to) external onlyOwner {
        treasuryFeeRecipient = _to;
        emit SetTreasuryFeeRecipient(_to);
    }
    function distributeWithdrawFee(IERC20 _token, address) external override {
        uint256 feeAmount = _token.balanceOf(address(this));
        uint256 treasuryFeeAmount = (feeAmount * treasuryFeeWithdraw) / withdrawFeeSum;
        if (treasuryFeeAmount > 0) {
            _token.safeTransfer(treasuryFeeRecipient, treasuryFeeAmount);
        }
        uint256 kswFeeAmount = (feeAmount * kswFeeWithdraw) / withdrawFeeSum;
        if (kswFeeAmount > 0) {
            _token.safeTransfer(kswFeeRecipient, kswFeeAmount);
        }
    }
}