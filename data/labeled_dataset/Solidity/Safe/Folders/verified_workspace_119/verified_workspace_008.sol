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
interface IByalanIsland {
    function izlude() external view returns (address);
}
pragma solidity 0.8.9;
interface ISailor {
    function MAX_FEE() external view returns (uint256);
    function totalFee() external view returns (uint256);
    function callFee() external view returns (uint256);
    function kswFee() external view returns (uint256);
}
pragma solidity 0.8.9;
interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfMasterChef() external view returns (uint256);
    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);
    function harvest() external;
    function retireStrategy() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
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
interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);
    function limitAllocation() external view returns (uint16);
    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}
pragma solidity 0.8.9;
interface IIzludeV2 {
    function totalSupply() external view returns (uint256);
    function prontera() external view returns (address);
    function want() external view returns (IERC20);
    function deposit(address user, uint256 amount) external returns (uint256 jellopy);
    function withdraw(address user, uint256 jellopy) external returns (uint256);
    function balance() external view returns (uint256);
    function byalan() external view returns (IByalan);
    function feeKafra() external view returns (IFeeKafra);
    function allocKafra() external view returns (IAllocKafra);
    function calculateWithdrawFee(uint256 amount, address user) external view returns (uint256);
}
pragma solidity 0.8.9;
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
pragma solidity 0.8.9;
contract PronteraV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using Address for address;
    using Address for address payable;
    IWETH public constant WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    struct UserInfo {
        uint256 jellopy;
        uint256 rewardDebt;
        uint256 storedJellopy;
    }
    struct PoolInfo {
        IERC20 want;
        address izlude;
        uint256 accKSWPerJellopy;
        uint64 allocPoint;
        uint64 lastRewardTime;
    }
    IPronteraReserve public immutable reserve;
    address public immutable ksw;
    uint256 public kswPerSecond;
    address[] public traversalPools;
    mapping(address => bool) public isInTraversalPools;
    mapping(address => PoolInfo) public poolInfo;
    uint256 public totalPool;
    uint256 public totalAllocPoint;
    mapping(address => mapping(address => UserInfo)) public userInfo;
    mapping(address => mapping(address => mapping(address => uint256))) private _storeAllowances;
    mapping(address => mapping(address => mapping(address => uint256))) public jellopyStorage;
    address public juno;
    address public junoGuide;
    event Deposit(address indexed user, address indexed izlude, uint256 amount);
    event DepositFor(address indexed user, address indexed izlude, uint256 amount);
    event DepositToken(address indexed user, address indexed izlude, uint256[] tokenAmount, uint256 amount);
    event DepositEther(address indexed user, address indexed izlude, uint256 value, uint256 amount);
    event Withdraw(address indexed user, address indexed izlude, uint256 amount);
    event WithdrawToken(address indexed user, address indexed izlude, uint256 jellopyAmount, uint256 tokenAmount);
    event WithdrawEther(address indexed user, address indexed izlude, uint256 jellopyAmount, uint256 value);
    event EmergencyWithdraw(address indexed user, address indexed izlude, uint256 amount);
    event StoreApproval(address indexed owner, address indexed izlude, address indexed spender, uint256 value);
    event StoreKeepJellopy(address indexed owner, address indexed izlude, address indexed store, uint256 value);
    event StoreReturnJellopy(address indexed user, address indexed izlude, address indexed store, uint256 amount);
    event StoreWithdraw(address indexed user, address indexed izlude, address indexed store, uint256 amount);
    event AddPool(address indexed izlude, uint256 allocPoint, bool withUpdate);
    event SetPool(address indexed izlude, uint256 allocPoint, bool withUpdate);
    event SetKSWPerSecond(uint256 kswPerSecond);
    event SetJuno(address juno);
    event SetJunoGuide(address junoGuide);
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Prontera: EXPIRED");
        _;
    }
    constructor(
        IPronteraReserve _reserve,
        address _ksw,
        uint256 _kswPerSecond,
        address _juno,
        address _junoGuide
    ) {
        reserve = _reserve;
        kswPerSecond = _kswPerSecond;
        juno = _juno;
        junoGuide = _junoGuide;
        ksw = _ksw;
    }
    function traversalPoolsLength() external view returns (uint256) {
        return traversalPools.length;
    }
    function _addTraversal(address izlude) private {
        if (isInTraversalPools[izlude]) {
            return;
        }
        isInTraversalPools[izlude] = true;
        traversalPools.push(izlude);
    }
    function removeTraversal(uint256 index) external {
        address izlude = traversalPools[index];
        require(poolInfo[izlude].allocPoint == 0, "allocated");
        isInTraversalPools[izlude] = false;
        traversalPools[index] = traversalPools[traversalPools.length - 1];
        traversalPools.pop();
    }
    function add(
        address izlude,
        uint64 allocPoint,
        bool withUpdate
    ) external onlyOwner {
        require(IIzludeV2(izlude).prontera() == address(this), "?");
        require(IIzludeV2(izlude).totalSupply() >= 0, "??");
        require(poolInfo[izlude].izlude == address(0), "duplicated");
        if (withUpdate) {
            massUpdatePools();
        }
        poolInfo[izlude] = PoolInfo({
            want: IIzludeV2(izlude).want(),
            izlude: izlude,
            allocPoint: allocPoint,
            lastRewardTime: uint64(block.timestamp),
            accKSWPerJellopy: 0
        });
        totalPool += 1;
        totalAllocPoint += allocPoint;
        if (allocPoint > 0) {
            _addTraversal(izlude);
        }
        emit AddPool(izlude, allocPoint, withUpdate);
    }
    function set(
        address izlude,
        uint64 allocPoint,
        bool withUpdate
    ) external onlyOwner {
        require(izlude != address(0), "invalid izlude");
        PoolInfo storage pool = poolInfo[izlude];
        require(pool.izlude == izlude, "!found");
        if (withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = (totalAllocPoint - pool.allocPoint) + allocPoint;
        pool.allocPoint = allocPoint;
        if (allocPoint > 0) {
            _addTraversal(izlude);
        }
        emit SetPool(izlude, allocPoint, withUpdate);
    }
    function pendingKSW(address izlude, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        uint256 accKSWPerJellopy = pool.accKSWPerJellopy;
        uint256 izludeSupply = IIzludeV2(izlude).totalSupply();
        if (block.timestamp > pool.lastRewardTime && izludeSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;
            uint256 stakingBal = reserve.balances();
            accKSWPerJellopy += (Math.min(kswReward, stakingBal) * 1e12) / izludeSupply;
        }
        uint256 tJellopy = user.jellopy + user.storedJellopy;
        uint256 r = ((tJellopy * accKSWPerJellopy) / 1e12) - user.rewardDebt;
        return r;
    }
    function massUpdatePools() public {
        for (uint256 i = 0; i < traversalPools.length; i++) {
            updatePool(traversalPools[i]);
        }
    }
    function updatePool(address izlude) public {
        PoolInfo storage pool = poolInfo[izlude];
        require(pool.izlude == izlude, "!pool");
        if (block.timestamp > pool.lastRewardTime) {
            uint256 izludeSupply = IIzludeV2(izlude).totalSupply();
            if (izludeSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;
                uint256 r = reserve.withdraw(address(this), kswReward);
                pool.accKSWPerJellopy += (r * 1e12) / izludeSupply;
            }
            pool.lastRewardTime = uint64(block.timestamp);
        }
    }
    function _deposit(
        address _user,
        address izlude,
        IERC20 want,
        uint256 amount
    ) private {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        updatePool(izlude);
        uint256 tJellopy = user.jellopy + user.storedJellopy;
        if (tJellopy > 0) {
            uint256 pending = ((tJellopy * pool.accKSWPerJellopy) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                IERC20(ksw).transfer(_user, pending);
            }
        }
        if (amount > 0) {
            want.safeIncreaseAllowance(izlude, amount);
            uint256 addAmount = IIzludeV2(izlude).deposit(_user, amount);
            tJellopy += addAmount;
            user.jellopy += addAmount;
        }
        user.rewardDebt = (tJellopy * pool.accKSWPerJellopy) / 1e12;
    }
    function harvest(address[] calldata izludes) external {
        for (uint256 i = 0; i < izludes.length; i++) {
            _deposit(msg.sender, izludes[i], IERC20(address(0)), 0);
        }
    }
    function deposit(address izlude, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        if (amount > 0) {
            require(_safeERC20TransferIn(pool.want, amount) == amount, "!amount");
        }
        _deposit(msg.sender, izlude, pool.want, amount);
        emit Deposit(msg.sender, izlude, amount);
    }
    function depositFor(
        address user,
        address izlude,
        uint256 amount
    ) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        if (amount > 0) {
            require(_safeERC20TransferIn(pool.want, amount) == amount, "!amount");
        }
        _deposit(user, izlude, pool.want, amount);
        emit DepositFor(user, izlude, amount);
    }
    function depositToken(
        address izlude,
        IERC20[] calldata tokens,
        uint256[] calldata tokenAmounts,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        require(tokens.length == tokenAmounts.length, "length mismatch");
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;
        uint256 beforeBal = want.balanceOf(address(this));
        for (uint256 i = 0; i < tokens.length; i++) {
            require(_safeERC20TransferIn(tokens[i], tokenAmounts[i]) == tokenAmounts[i], "!amount");
            if (tokens[i] != want) {
                tokens[i].safeTransfer(juno, tokenAmounts[i]);
            }
        }
        juno.functionCall(data, "juno: failed");
        uint256 amount = want.balanceOf(address(this)) - beforeBal;
        require(amount >= amountOutMin, "insufficient output amount");
        _deposit(msg.sender, izlude, want, amount);
        emit DepositToken(msg.sender, izlude, tokenAmounts, amount);
    }
    function depositEther(
        address izlude,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external payable nonReentrant ensure(deadline) {
        require(msg.value > 0, "!value");
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;
        uint256 beforeBal = want.balanceOf(address(this));
        WETH.deposit{value: msg.value}();
        WETH.safeTransfer(juno, msg.value);
        juno.functionCall(data, "juno: failed");
        uint256 afterBal = want.balanceOf(address(this));
        uint256 amount = afterBal - beforeBal;
        require(amount >= amountOutMin, "insufficient output amount");
        _deposit(msg.sender, izlude, want, amount);
        emit DepositEther(msg.sender, izlude, msg.value, amount);
    }
    function _withdraw(
        address _user,
        address izlude,
        IERC20 want,
        uint256 jellopyAmount
    ) private returns (uint256 amount) {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        jellopyAmount = Math.min(user.jellopy, jellopyAmount);
        updatePool(izlude);
        uint256 tJellopy = user.jellopy + user.storedJellopy;
        uint256 pending = ((tJellopy * pool.accKSWPerJellopy) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            IERC20(ksw).transfer(_user, pending);
        }
        tJellopy -= jellopyAmount;
        user.jellopy -= jellopyAmount;
        user.rewardDebt = (tJellopy * pool.accKSWPerJellopy) / 1e12;
        if (jellopyAmount > 0) {
            uint256 wantBefore = want.balanceOf(address(this));
            IIzludeV2(izlude).withdraw(_user, jellopyAmount);
            uint256 wantAfter = want.balanceOf(address(this));
            amount = wantAfter - wantBefore;
        }
    }
    function withdraw(address izlude, uint256 jellopyAmount) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        uint256 amount = _withdraw(msg.sender, izlude, pool.want, jellopyAmount);
        if (amount > 0) {
            pool.want.safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, izlude, jellopyAmount);
    }
    function storeWithdraw(
        address _user,
        address izlude,
        uint256 jellopyAmount
    ) external nonReentrant {
        require(jellopyAmount > 0, "invalid amount");
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        jellopyStorage[_user][izlude][msg.sender] -= jellopyAmount;
        user.storedJellopy -= jellopyAmount;
        user.jellopy += jellopyAmount;
        uint256 amount = _withdraw(_user, izlude, pool.want, jellopyAmount);
        if (amount > 0) {
            pool.want.safeTransfer(msg.sender, amount);
        }
        emit StoreWithdraw(_user, izlude, msg.sender, amount);
    }
    function withdrawToken(
        address izlude,
        IERC20 token,
        uint256 jellopyAmount,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;
        require(token != want, "!want");
        uint256 amount = _withdraw(msg.sender, izlude, want, jellopyAmount);
        uint256 beforeBal = token.balanceOf(msg.sender);
        want.safeTransfer(juno, amount);
        juno.functionCall(data, "juno: failed");
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        uint256 afterBal = token.balanceOf(msg.sender);
        uint256 amountOut = afterBal - beforeBal;
        require(amountOut >= amountOutMin, "insufficient output amount");
        emit WithdrawToken(msg.sender, izlude, amountOut, jellopyAmount);
    }
    function withdrawEther(
        address izlude,
        uint256 jellopyAmount,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        PoolInfo storage pool = poolInfo[izlude];
        uint256 amount = _withdraw(msg.sender, izlude, pool.want, jellopyAmount);
        uint256 beforeBal = WETH.balanceOf(address(this));
        pool.want.safeTransfer(juno, amount);
        juno.functionCall(data, "juno: failed");
        uint256 afterBal = WETH.balanceOf(address(this));
        uint256 amountOut = afterBal - beforeBal;
        require(amountOut >= amountOutMin, "insufficient output amount");
        WETH.withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);
        emit WithdrawEther(msg.sender, izlude, jellopyAmount, amountOut);
    }
    function emergencyWithdraw(address izlude) external {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][msg.sender];
        uint256 jellopy = user.jellopy;
        user.jellopy = 0;
        user.rewardDebt = (user.storedJellopy * pool.accKSWPerJellopy) / 1e12;
        if (jellopy > 0) {
            IERC20 want = pool.want;
            uint256 wantBefore = want.balanceOf(address(this));
            IIzludeV2(izlude).withdraw(msg.sender, jellopy);
            uint256 wantAfter = want.balanceOf(address(this));
            want.safeTransfer(msg.sender, wantAfter - wantBefore);
        }
        emit EmergencyWithdraw(msg.sender, izlude, jellopy);
    }
    function storeAllowance(
        address user,
        address izlude,
        address store
    ) external view returns (uint256) {
        return _storeAllowances[user][izlude][store];
    }
    function _approveStore(
        address user,
        address izlude,
        address store,
        uint256 amount
    ) private {
        require(user != address(0), "approve from the zero address");
        require(izlude != address(0), "approve izlude zero address");
        require(store != address(0), "approve to the zero address");
        _storeAllowances[user][izlude][store] = amount;
        emit StoreApproval(user, izlude, store, amount);
    }
    function approveStore(
        address izlude,
        address store,
        uint256 amount
    ) external {
        _approveStore(msg.sender, izlude, store, amount);
    }
    function increaseStoreAllowance(
        address izlude,
        address store,
        uint256 addedAmount
    ) external {
        _approveStore(msg.sender, izlude, store, _storeAllowances[msg.sender][izlude][store] + addedAmount);
    }
    function decreaseStoreAllowance(
        address izlude,
        address store,
        uint256 subtractedAmount
    ) external {
        uint256 currentAllowance = _storeAllowances[msg.sender][izlude][store];
        require(currentAllowance >= subtractedAmount, "decreased allowance below zero");
        unchecked {
            _approveStore(msg.sender, izlude, store, currentAllowance - subtractedAmount);
        }
    }
    function storeKeepJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external {
        require(amount > 0, "invalid amount");
        UserInfo storage user = userInfo[izlude][_user];
        user.jellopy -= amount;
        user.storedJellopy += amount;
        jellopyStorage[_user][izlude][msg.sender] += amount;
        uint256 currentAllowance = _storeAllowances[_user][izlude][msg.sender];
        require(currentAllowance >= amount, "keep amount exceeds allowance");
        unchecked {
            _approveStore(_user, izlude, msg.sender, currentAllowance - amount);
        }
        emit StoreKeepJellopy(_user, izlude, msg.sender, amount);
    }
    function storeReturnJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external {
        require(amount > 0, "invalid amount");
        UserInfo storage user = userInfo[izlude][_user];
        jellopyStorage[_user][izlude][msg.sender] -= amount;
        user.storedJellopy -= amount;
        user.jellopy += amount;
        emit StoreReturnJellopy(_user, izlude, msg.sender, amount);
    }
    function setKSWPerSecond(uint256 _kswPerSecond) external onlyOwner {
        massUpdatePools();
        kswPerSecond = _kswPerSecond;
        emit SetKSWPerSecond(_kswPerSecond);
    }
    function setJuno(address _juno) external {
        require(msg.sender == junoGuide, "!guide");
        juno = _juno;
        emit SetJuno(_juno);
    }
    function setJunoGuide(address _junoGuide) external onlyOwner {
        junoGuide = _junoGuide;
        emit SetJunoGuide(_junoGuide);
    }
    function _safeERC20TransferIn(IERC20 token, uint256 amount) private returns (uint256) {
        require(amount > 0, "zero amount");
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
    receive() external payable {
        require(msg.sender == address(WETH), "reject");
    }
}