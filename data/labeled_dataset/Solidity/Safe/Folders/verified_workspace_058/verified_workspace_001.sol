pragma solidity 0.6.12;
import './math/SafeMath.sol';
import './token/BEP20/IBEP20.sol';
import './token/BEP20/SafeBEP20.sol';
import './access/Ownable.sol';
interface IMigratorChef {
    function migrate(IBEP20 token) external returns (IBEP20);
}
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accXttPerShare;
        uint256 executeTimestamp;
        bool withUpdate;
        bool executed;
    }
    struct PoolAllocPointInfo {
        uint256 pid;
        uint256 allocPoint;
        uint256 executeTimestamp;
        bool withUpdate;
        bool executed;
    }
    IBEP20 public xtt;
    uint256 public xttPerBlock;
    uint256 public BONUS_MULTIPLIER = 1;
    uint256 public NEW_BONUS_MULTIPLIER = 1;
    uint256 public NEW_BONUS_MULTIPLIER_TIMESTAMP = 0;
    IMigratorChef public migrator;
    IMigratorChef public newMigrator;
    uint256 public newMigratorExecuteTimestamp = 0;
    PoolInfo[] public poolInfo;
    PoolInfo[] public waitingPoolInfo;
    PoolAllocPointInfo[] public poolAllocPointInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    uint256 public constant MIN_TIME_LOCK_PERIOD = 24 hours;
    uint256 public constant MAX_ARRAY_LENGTH = 100;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetMigrator(address indexed user, IMigratorChef migrator);
    event UpdateMultiplier(address indexed user, uint256 multiplierNumber);
    constructor(
        IBEP20 _xtt,
        uint256 _xttPerBlock,
        uint256 _startBlock
    ) public {
        xtt = _xtt;
        xttPerBlock = _xttPerBlock;
        startBlock = _startBlock;
        poolInfo.push(PoolInfo({
            lpToken: _xtt,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accXttPerShare: 0,
            executeTimestamp: block.timestamp,
            withUpdate: false,
            executed: true
        }));
        totalAllocPoint = 1000;
    }
    function updateMultiplier(uint256 multiplierNumber, uint256 executeTimestamp) external onlyOwner {
        require(
            executeTimestamp >= block.timestamp.add(MIN_TIME_LOCK_PERIOD),
            "executeTimestamp cannot be sooner than MIN_TIME_LOCK_PERIOD"
        );
        if(NEW_BONUS_MULTIPLIER_TIMESTAMP > 0 && block.timestamp >= NEW_BONUS_MULTIPLIER_TIMESTAMP){
            if(BONUS_MULTIPLIER != NEW_BONUS_MULTIPLIER){
                BONUS_MULTIPLIER = NEW_BONUS_MULTIPLIER;
            }
        }
        NEW_BONUS_MULTIPLIER = multiplierNumber;
        NEW_BONUS_MULTIPLIER_TIMESTAMP = executeTimestamp;
        emit UpdateMultiplier(msg.sender, multiplierNumber);
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate, uint256 _executeTimestamp) external onlyOwner {
        require(
            _executeTimestamp >= block.timestamp.add(MIN_TIME_LOCK_PERIOD),
            "_executeTimestamp cannot be sooner than MIN_TIME_LOCK_PERIOD"
        );
        require(
            waitingPoolInfo.length < MAX_ARRAY_LENGTH,
            "Please call executeAddPools function to process adding previous pools before adding more pools"
        );
        waitingPoolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: 0,
            accXttPerShare: 0,
            executeTimestamp: _executeTimestamp,
            withUpdate: _withUpdate,
            executed: false
        }));
    }
    function executeAddPools() external onlyOwner {
        uint256 length = waitingPoolInfo.length;
        if(length > 0){
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = waitingPoolInfo[pid];
                if(!pool.executed && pool.executeTimestamp <= block.timestamp){
                    if (pool.withUpdate) {
                        massUpdatePools();
                    }
                    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
                    totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
                    poolInfo.push(PoolInfo({
                        lpToken: pool.lpToken,
                        allocPoint: pool.allocPoint,
                        lastRewardBlock: lastRewardBlock,
                        accXttPerShare: 0,
                        executeTimestamp: pool.executeTimestamp,
                        withUpdate: pool.withUpdate,
                        executed: true
                    }));
                    pool.executed = true;
                    updateStakingPool();
                    removeWaitingPool(pid);
                    pid--;
                    length--;
                }
            }
        }
    }
    function removeWaitingPool(uint index)  internal onlyOwner {
        if (index >= waitingPoolInfo.length) return;
        for (uint i = index; i<waitingPoolInfo.length-1; i++){
            waitingPoolInfo[i] = waitingPoolInfo[i+1];
        }
        waitingPoolInfo.pop();
    }
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate, uint256 _executeTimestamp) external onlyOwner {
        require(
            _executeTimestamp >= block.timestamp.add(MIN_TIME_LOCK_PERIOD),
            "_executeTimestamp cannot be sooner than MIN_TIME_LOCK_PERIOD"
        );
        require(
            poolAllocPointInfo.length < MAX_ARRAY_LENGTH,
            "Please call executeUpdateAllocPoint function to process previous data before updating more pools"
        );
        poolAllocPointInfo.push(PoolAllocPointInfo({
            pid: _pid,
            allocPoint: _allocPoint,
            executeTimestamp: _executeTimestamp,
            withUpdate: _withUpdate,
            executed: false
        }));
    }
    function executeUpdateAllocPoint() external onlyOwner {
        uint256 length = poolAllocPointInfo.length;
        if(length > 0){
            for (uint256 index = 0; index < length; ++index) {
                PoolAllocPointInfo storage poolAllocPoint = poolAllocPointInfo[index];
                if(!poolAllocPoint.executed && poolAllocPoint.executeTimestamp <= block.timestamp){
                    if (poolAllocPoint.withUpdate) {
                        massUpdatePools();
                    }else{
                        updatePool(poolAllocPoint.pid);
                    }
                    uint256 prevAllocPoint = poolInfo[poolAllocPoint.pid].allocPoint;
                    if (prevAllocPoint != poolAllocPoint.allocPoint) {
                        poolInfo[poolAllocPoint.pid].allocPoint = poolAllocPoint.allocPoint;
                        totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(poolAllocPoint.allocPoint);
                        updateStakingPool();
                    }
                    poolAllocPoint.executed = true;
                    removeAllocPoint(index);
                    index--;
                    length--;
                }
            }
        }
    }
    function removeAllocPoint(uint index)  internal onlyOwner {
        if (index >= poolAllocPointInfo.length) return;
        for (uint i = index; i<poolAllocPointInfo.length-1; i++){
            poolAllocPointInfo[i] = poolAllocPointInfo[i+1];
        }
        poolAllocPointInfo.pop();
    }
    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }
    function setMigrator(IMigratorChef _migrator, uint256 _executeTimestamp) external onlyOwner {
        require(
            _executeTimestamp >= block.timestamp.add(MIN_TIME_LOCK_PERIOD),
            "_executeTimestamp cannot be sooner than MIN_TIME_LOCK_PERIOD"
        );
        newMigrator = _migrator;
        newMigratorExecuteTimestamp = _executeTimestamp;
        emit SetMigrator(msg.sender, _migrator);
    }
    function executeSetMigrator() external onlyOwner {
        if(newMigratorExecuteTimestamp > 0 && newMigratorExecuteTimestamp <= block.timestamp){
            migrator = newMigrator;
            newMigratorExecuteTimestamp = 0;
            emit SetMigrator(msg.sender, newMigrator);
        }
    }
    function migrate(uint256 _pid) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if(NEW_BONUS_MULTIPLIER_TIMESTAMP > 0 && block.timestamp >= NEW_BONUS_MULTIPLIER_TIMESTAMP){
            return _to.sub(_from).mul(NEW_BONUS_MULTIPLIER);
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXttPerShare = pool.accXttPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(xttPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accXttPerShare = accXttPerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accXttPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 xttReward = multiplier.mul(xttPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accXttPerShare = pool.accXttPerShare.add(xttReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    function deposit(uint256 _pid, uint256 _amount) external {
        require (_pid != 0, 'deposit XTT by staking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accXttPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeXttTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXttPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    function withdraw(uint256 _pid, uint256 _amount) external {
        require (_pid != 0, 'withdraw XTT by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accXttPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeXttTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXttPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    function enterStaking(uint256 _amount) external {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accXttPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeXttTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXttPerShare).div(1e12);
        emit Deposit(msg.sender, 0, _amount);
    }
    function leaveStaking(uint256 _amount) external {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accXttPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeXttTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXttPerShare).div(1e12);
        emit Withdraw(msg.sender, 0, _amount);
    }
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
    function safeXttTransfer(address _to, uint256 _amount) internal {
        xtt.safeTransfer(_to, _amount);
    }
}