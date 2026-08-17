pragma solidity 0.8.10;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
interface IStatikMaster {
    function withdrawThorus(uint256 amount) external;
}
contract StatikWithdrawer is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable thorus;
    IStatikMaster public statikMaster;
    bool public isMasterChangeInitiated = false;
    uint256 public contractChangeTimestamp;
    IStatikMaster public newStatikMaster;
    event Withdraw(uint256 amount);
    event Deposit(uint256 amount);
    event InitiateMasterChange(uint256 timestamp, address newStatikMaster);
    event CancelMasterChange();
    event MasterChanged(address statikMaster);
    constructor(IERC20 _thorus, IStatikMaster _statikMaster) {
        require(
            address(_thorus) != address(0) &&
            address(_statikMaster) != address(0),
            "zero address in constructor"
        );
        thorus = _thorus;
        statikMaster = _statikMaster;
    }
    function withdraw(uint256 amount) external onlyOwner {
        statikMaster.withdrawThorus(amount);
        emit Withdraw(amount);
    }
    function deposit(uint256 amount) external onlyOwner {
        thorus.safeTransfer(address(statikMaster), amount);
        emit Deposit(amount);
    }
    function initiateMasterChange(uint256 timestamp, IStatikMaster _statikMaster) external onlyOwner {
        require(!isMasterChangeInitiated, 'change already initiated');
        require(timestamp >= block.timestamp + 24 hours, 'timestamp not valid!');
        require(address(_statikMaster) != address(0),"zero address");
        isMasterChangeInitiated = true;
        contractChangeTimestamp = timestamp;
        newStatikMaster = _statikMaster;
        emit InitiateMasterChange(timestamp, address(_statikMaster));
    }
    function cancelMasterChange() external onlyOwner {
        require(isMasterChangeInitiated, 'change not initiated');
        isMasterChangeInitiated = false;
        contractChangeTimestamp = 0;
        newStatikMaster = IStatikMaster(address(0));
        emit CancelMasterChange();
    }
    function changeMaster() external onlyOwner {
        require(isMasterChangeInitiated, 'change not initiated');
        require(block.timestamp >= contractChangeTimestamp, 'not yet possible');
        statikMaster = newStatikMaster;
        isMasterChangeInitiated = false;
        contractChangeTimestamp = 0;
        newStatikMaster = IStatikMaster(address(0));
        emit MasterChanged(address(statikMaster));
    }
}