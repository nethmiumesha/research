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
pragma solidity ^0.8.0;
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
pragma solidity 0.8.9;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
pragma solidity 0.8.9;
interface IPronteraReserve {
    function balances() external view returns (uint256);
    function withdraw(address to, uint256 amount) external returns (uint256);
}
pragma solidity 0.8.9;
contract Emperium is Ownable {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo {
        IERC20 token;
        uint256 accKSWPerShare;
        uint64 allocPoint;
        uint64 lastRewardTime;
    }
    IPronteraReserve public immutable reserve;
    address public immutable ksw;
    uint256 public kswPerSecond;
    uint256 public totalKSWDeposited;
    PoolInfo[] public poolInfo;
    uint256 public totalAllocPoint;
    mapping(IERC20 => bool) public isTokenInPool;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event AddPool(uint256 indexed pid, IERC20 indexed token, uint256 allocPoint);
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event SetKSWPerSecond(uint256 kswPerSecond);
    constructor(
        IPronteraReserve _reserve,
        address _ksw,
        uint256 _kswPerSecond
    ) {
        reserve = _reserve;
        kswPerSecond = _kswPerSecond;
        ksw = _ksw;
    }
    function add(IERC20 token, uint64 allocPoint) external onlyOwner {
        require(!isTokenInPool[token], "duplicated");
        massUpdatePools();
        isTokenInPool[token] = true;
        totalAllocPoint += allocPoint;
        poolInfo.push(
            PoolInfo({token: token, allocPoint: allocPoint, lastRewardTime: uint64(block.timestamp), accKSWPerShare: 0})
        );
        emit AddPool(poolInfo.length - 1, token, allocPoint);
    }
    function set(uint256 pid, uint64 allocPoint) external onlyOwner {
        massUpdatePools();
        totalAllocPoint = (totalAllocPoint - poolInfo[pid].allocPoint) + allocPoint;
        poolInfo[pid].allocPoint = allocPoint;
        emit SetPool(pid, allocPoint);
    }
    function pendingKSW(uint256 pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accKSWPerShare = pool.accKSWPerShare;
        uint256 tokenSupply = address(pool.token) == ksw ? totalKSWDeposited : pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;
            uint256 stakingBal = reserve.balances();
            accKSWPerShare += (Math.min(kswReward, stakingBal) * 1e12) / tokenSupply;
        }
        uint256 r = ((user.amount * accKSWPerShare) / 1e12) - user.rewardDebt;
        return r;
    }
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 tokenSupply = address(pool.token) == ksw ? totalKSWDeposited : pool.token.balanceOf(address(this));
            if (tokenSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;
                uint256 r = reserve.withdraw(address(this), kswReward);
                pool.accKSWPerShare += (r * 1e12) / tokenSupply;
            }
            pool.lastRewardTime = uint64(block.timestamp);
        }
    }
    function deposit(uint256 pid, uint256 amount) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accKSWPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                IERC20(ksw).transfer(msg.sender, pending);
            }
        }
        user.amount += amount;
        user.rewardDebt = (user.amount * pool.accKSWPerShare) / 1e12;
        if (amount > 0) {
            require(_safeERC20TransferIn(pool.token, amount) == amount, "!amount");
            if (address(pool.token) == ksw) {
                totalKSWDeposited += amount;
            }
        }
        emit Deposit(msg.sender, pid, amount);
    }
    function withdraw(uint256 pid, uint256 amount) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updatePool(pid);
        uint256 pending = ((user.amount * pool.accKSWPerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            IERC20(ksw).transfer(msg.sender, pending);
        }
        user.amount -= amount;
        user.rewardDebt = (user.amount * pool.accKSWPerShare) / 1e12;
        if (amount > 0) {
            if (address(pool.token) == ksw) {
                totalKSWDeposited -= amount;
            }
            pool.token.safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, pid, amount);
    }
    function emergencyWithdraw(uint256 pid) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (address(pool.token) == ksw) {
            totalKSWDeposited -= amount;
        }
        pool.token.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount);
    }
    function setKSWPerSecond(uint256 _kswPerSecond) external onlyOwner {
        massUpdatePools();
        kswPerSecond = _kswPerSecond;
        emit SetKSWPerSecond(_kswPerSecond);
    }
    function _safeERC20TransferIn(IERC20 token, uint256 amount) private returns (uint256) {
        require(amount > 0, "zero amount");
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}