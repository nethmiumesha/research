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
        _transferOwnership(_msgSender());
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
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
interface IAutoStake {
    function deposit(address user, uint256 amount) external;
}
contract ThorusBond is Ownable {
    using SafeERC20 for IERC20;
    address public immutable thorus;
    address public immutable principal;
    address public immutable treasury;
    address public immutable staking;
    uint256 public thorusAvailableToPay;
    uint256 public vestingSeconds;
    uint256 public thorusPerPrincipal;
    uint256 public ratioPrecision;
    uint256 public totalPrincipalReceived;
    struct UserInfo {
        uint256 remainingPayout;
        uint256 remainingVestingSeconds;
        uint256 lastInteractionSecond;
    }
    mapping(address => UserInfo) public userInfo;
    event ThorusAdded(uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 payout);
    event Claim(address indexed user, uint256 payout, bool staked);
    event RatioChanged(uint256 oldThorusPerPrincipal, uint256 newThorusPerPrincipal, uint256 oldRatioPrecision, uint256 newRatioPrecision);
    constructor (
        address _thorus,
        address _principal,
        address _treasury,
        address _staking,
        uint256 _vestingSeconds,
        uint256 _thorusPerPrincipal,
        uint256 _ratioPrecision
    ) {
        require(_thorus != address(0) && _principal != address(0) && _treasury != address(0) && _staking != address(0), 'zero address');
        thorus = _thorus;
        principal = _principal;
        treasury = _treasury;
        staking = _staking;
        require(_vestingSeconds > 0, 'zero vesting');
        vestingSeconds = _vestingSeconds;
        require(_thorusPerPrincipal != 0, 'ratio cant be zero');
        thorusPerPrincipal = _thorusPerPrincipal;
        require(_ratioPrecision != 0, 'precision cant be zero');
        ratioPrecision = _ratioPrecision;
    }
    function setRatio(uint256 _thorusPerPrincipal, uint256 _ratioPrecision) external onlyOwner {
        emit RatioChanged(thorusPerPrincipal, _thorusPerPrincipal, ratioPrecision, _ratioPrecision);
        require(_thorusPerPrincipal != 0, 'ratio cant be zero');
        thorusPerPrincipal = _thorusPerPrincipal;
        require(_ratioPrecision != 0, 'precision cant be zero');
        ratioPrecision = _ratioPrecision;
    }
    function addThorusToPay(uint256 amount) external {
        IERC20(thorus).safeTransferFrom(msg.sender, address(this), amount);
        thorusAvailableToPay += amount;
        emit ThorusAdded(amount);
    }
    function deposit(uint256 amount) external returns (uint256) {
        uint256 payout;
        payout = amount * thorusPerPrincipal / ratioPrecision;
        require(payout > 0, "too small");
        require(thorusAvailableToPay >= payout, "sell out");
        if(claimablePayout(msg.sender) > 0)
            claim(false);
        IERC20(principal).safeTransferFrom(msg.sender, treasury, amount);
        totalPrincipalReceived += amount;
        thorusAvailableToPay -= payout;
        userInfo[msg.sender] = UserInfo({
            remainingPayout: userInfo[msg.sender].remainingPayout + payout,
            remainingVestingSeconds: vestingSeconds,
            lastInteractionSecond: block.timestamp
        });
        emit Deposit(msg.sender, amount, payout);
        return payout;
    }
    function claimablePayout(address user) public view returns (uint256) {
        UserInfo memory info = userInfo[user];
        uint256 secondsSinceLastInteraction = block.timestamp - info.lastInteractionSecond;
        if(secondsSinceLastInteraction > info.remainingVestingSeconds)
            return info.remainingPayout;
        return info.remainingPayout * secondsSinceLastInteraction / info.remainingVestingSeconds;
    }
    function claim(bool autoStake) public returns (uint256) {
        UserInfo memory info = userInfo[msg.sender];
        uint256 secondsSinceLastInteraction = block.timestamp - info.lastInteractionSecond;
        uint256 payout;
        if(secondsSinceLastInteraction >= info.remainingVestingSeconds) {
            payout = info.remainingPayout;
            delete userInfo[msg.sender];
        } else {
            payout = info.remainingPayout * secondsSinceLastInteraction / info.remainingVestingSeconds;
            userInfo[msg.sender] = UserInfo({
                remainingPayout: info.remainingPayout - payout,
                remainingVestingSeconds: info.remainingVestingSeconds - secondsSinceLastInteraction,
                lastInteractionSecond: block.timestamp
            });
        }
        if(autoStake) {
            IERC20(thorus).approve(staking, payout);
            IAutoStake(staking).deposit(msg.sender, payout);
        } else {
            IERC20(thorus).safeTransfer(msg.sender, payout);
        }
        emit Claim(msg.sender, payout, autoStake);
        return payout;
    }
}