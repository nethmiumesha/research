import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity 0.6.12;
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unstakeTime;
    }
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardTokenPerShare;
    }
    IERC20 public rewardToken;
    uint256 public bonusEndBlock;
    uint256 public rewardTokenPerBlock;
    uint256 public constant BONUS_MULTIPLIER = 10;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startRewardBlock;
    uint256 public endRewardBlock;
    uint256 public unstakeFrozenTime = 72 hours;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    constructor(
        IERC20 _rewardToken,
        uint256 _rewardTokenPerBlock,
        uint256 _startRewardBlock,
        uint256 _endRewardBlock,
        uint256 _bonusEndBlock
    ) public {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startRewardBlock = _startRewardBlock;
        endRewardBlock = _endRewardBlock;
        bonusEndBlock = _bonusEndBlock;
    }
    function setAll(
        IERC20 _rewardToken,
        uint256 _rewardTokenPerBlock,
        uint256 _startRewardBlock,
        uint256 _endRewardBlock,
        uint256 _bonusEndBlock,
        uint256 _unstakeFrozenTime
    ) public onlyOwner {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startRewardBlock = _startRewardBlock;
        endRewardBlock = _endRewardBlock;
        bonusEndBlock = _bonusEndBlock;
        unstakeFrozenTime = _unstakeFrozenTime;
    }
    function setRewardToken(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }
    function setUnstakeFrozenTime(uint256 _unstakeFrozenTime) public onlyOwner {
        unstakeFrozenTime = _unstakeFrozenTime;
    }
    function setRewardTokenPerBlock(uint256 _rewardTokenPerBlock)
        public
        onlyOwner
    {
        rewardTokenPerBlock = _rewardTokenPerBlock;
    }
    function setStartRewardBlock(uint256 _startRewardBlock) public onlyOwner {
        startRewardBlock = _startRewardBlock;
    }
    function setEndRewardBlock(uint256 _endRewardBlock) public onlyOwner {
        endRewardBlock = _endRewardBlock;
    }
    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startRewardBlock ? block.number : startRewardBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardTokenPerShare: 0
            })
        );
    }
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }
    function pendingRewardToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardTokenReward =
                multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardTokenPerShare = accRewardTokenPerShare.add(
                rewardTokenReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
    }
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward =
            multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(
            rewardTokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (now > user.unstakeTime)
                safeRewardTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.unstakeTime = now + unstakeFrozenTime;
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(
            1e12
        );
        emit Deposit(msg.sender, _pid, _amount);
    }
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        if (now > user.unstakeTime) {
            updatePool(_pid);
            uint256 pending =
                user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeRewardTokenTransfer(msg.sender, pending);
            user.amount = user.amount.sub(_amount);
            user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(
                1e12
            );
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            emit Withdraw(msg.sender, _pid, _amount);
        }
    }
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        if (
            block.number >= startRewardBlock && block.number <= endRewardBlock
        ) {
            uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
            if (_amount > rewardTokenBal) {
                rewardToken.transfer(_to, rewardTokenBal);
            } else {
                rewardToken.transfer(_to, _amount);
            }
        }
    }
    IMigratorChef public migrator;
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }
    function depositRewardTokens(uint256 _amount) public onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), _amount);
    }
    function withdrawRewardTokens(uint256 _amount) public onlyOwner {
        rewardToken.transfer(msg.sender, _amount);
    }
}
interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}