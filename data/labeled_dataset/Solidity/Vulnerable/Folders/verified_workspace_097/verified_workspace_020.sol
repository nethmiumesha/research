pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;
import "../Math/Math.sol";
import "../Math/SafeMath.sol";
import "../Curve/IveFXS.sol";
import "../ERC20/ERC20.sol";
import '../Uniswap/TransferHelper.sol';
import "../ERC20/SafeERC20.sol";
import "../Frax/Frax.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";
import "../Utils/ReentrancyGuard.sol";
import "./Owned.sol";
contract StakingRewardsDualV5 is Owned, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    IveFXS private veFXS;
    ERC20 private rewardsToken0;
    ERC20 private rewardsToken1;
    IUniswapV2Pair private stakingToken;
    uint256 private constant MULTIPLIER_PRECISION = 1e18;
    address public timelock_address;
    address public controller_address;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public lock_max_multiplier = uint256(3e18);
    uint256 public lock_time_for_max_multiplier = 3 * 365 * 86400;
    uint256 public lock_time_min = 86400;
    uint256 public vefxs_per_frax_for_max_boost = uint256(4e18);
    uint256 public vefxs_max_multiplier = uint256(2e18);
    mapping(address => uint256) private _vefxsMultiplierStored;
    uint256 public rewardRate0;
    uint256 public rewardRate1;
    uint256 public rewardsDuration = 604800;
    uint256 private rewardPerTokenStored0;
    uint256 private rewardPerTokenStored1 = 0;
    mapping(address => uint256) public userRewardPerTokenPaid0;
    mapping(address => uint256) public userRewardPerTokenPaid1;
    mapping(address => uint256) public rewards0;
    mapping(address => uint256) public rewards1;
    uint256 private _total_liquidity_locked;
    uint256 private _total_combined_weight;
    mapping(address => uint256) private _locked_liquidity;
    mapping(address => uint256) private _combined_weights;
    bool frax_is_token0;
    mapping(address => LockedStake[]) private lockedStakes;
    mapping(address => bool) public valid_migrators;
    mapping(address => mapping(address => bool)) public staker_allowed_migrators;
    mapping(address => bool) public greylist;
    bool public token1_rewards_on = true;
    bool public migrationsOn;
    bool public stakesUnlocked;
    bool public withdrawalsPaused;
    bool public rewardsCollectionPaused;
    bool public stakingPaused;
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier;
    }
    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
        _;
    }
    modifier onlyByOwnGovCtrlr() {
        require(msg.sender == owner || msg.sender == timelock_address || msg.sender == controller_address, "Not own, tlk, or ctrlr");
        _;
    }
    modifier isMigrating() {
        require(migrationsOn == true, "Not in migration");
        _;
    }
    modifier notStakingPaused() {
        require(stakingPaused == false, "Staking paused");
        _;
    }
    modifier updateRewardAndBalance(address account, bool sync_too) {
        _updateRewardAndBalance(account, sync_too);
        _;
    }
    constructor (
        address _owner,
        address _rewardsToken0,
        address _rewardsToken1,
        address _stakingToken,
        address _frax_address,
        address _timelock_address,
        address _veFXS_address
    ) Owned(_owner){
        rewardsToken0 = ERC20(_rewardsToken0);
        rewardsToken1 = ERC20(_rewardsToken1);
        stakingToken = IUniswapV2Pair(_stakingToken);
        veFXS = IveFXS(_veFXS_address);
        timelock_address = _timelock_address;
        rewardRate0 = 0;
        rewardRate1 = 0;
        address token0 = stakingToken.token0();
        if (token0 == _frax_address) frax_is_token0 = true;
        else frax_is_token0 = false;
        migrationsOn = false;
        stakesUnlocked = false;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }
    function totalLiquidityLocked() external view returns (uint256) {
        return _total_liquidity_locked;
    }
    function lockedLiquidityOf(address account) external view returns (uint256) {
        return _locked_liquidity[account];
    }
    function totalCombinedWeight() external view returns (uint256) {
        return _total_combined_weight;
    }
    function combinedWeightOf(address account) external view returns (uint256) {
        return _combined_weights[account];
    }
    function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
        return lockedStakes[account];
    }
    function lockMultiplier(uint256 secs) public view returns (uint256) {
        uint256 lock_multiplier =
            uint256(MULTIPLIER_PRECISION).add(
                secs
                    .mul(lock_max_multiplier.sub(MULTIPLIER_PRECISION))
                    .div(lock_time_for_max_multiplier)
            );
        if (lock_multiplier > lock_max_multiplier) lock_multiplier = lock_max_multiplier;
        return lock_multiplier;
    }
    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }
    function fraxPerLPToken() public view returns (uint256) {
        uint256 frax_per_lp_token;
        {
            uint256 total_frax_reserves;
            (uint256 reserve0, uint256 reserve1, ) = (stakingToken.getReserves());
            if (frax_is_token0) total_frax_reserves = reserve0;
            else total_frax_reserves = reserve1;
            frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
        }
        return frax_per_lp_token;
    }
    function userStakedFrax(address account) public view returns (uint256) {
        return (fraxPerLPToken()).mul(_locked_liquidity[account]).div(1e18);
    }
    function minVeFXSForMaxBoost(address account) public view returns (uint256) {
        return (userStakedFrax(account)).mul(vefxs_per_frax_for_max_boost).div(MULTIPLIER_PRECISION);
    }
    function veFXSMultiplier(address account) public view returns (uint256) {
        uint256 veFXS_needed_for_max_boost = minVeFXSForMaxBoost(account);
        if (veFXS_needed_for_max_boost > 0){
            uint256 user_vefxs_fraction = (veFXS.balanceOf(account)).mul(MULTIPLIER_PRECISION).div(veFXS_needed_for_max_boost);
            uint256 vefxs_multiplier = ((user_vefxs_fraction).mul(vefxs_max_multiplier)).div(MULTIPLIER_PRECISION);
            if (vefxs_multiplier > vefxs_max_multiplier) vefxs_multiplier = vefxs_max_multiplier;
            return vefxs_multiplier;
        }
        else return 0;
    }
    function calcCurCombinedWeight(address account) public view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        )
    {
        old_combined_weight = _combined_weights[account];
        new_vefxs_multiplier = veFXSMultiplier(account);
        uint256 midpoint_vefxs_multiplier;
        if (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) {
            midpoint_vefxs_multiplier = new_vefxs_multiplier;
        }
        else {
            midpoint_vefxs_multiplier = ((new_vefxs_multiplier).add(_vefxsMultiplierStored[account])).div(2);
        }
        new_combined_weight = 0;
        for (uint256 i = 0; i < lockedStakes[account].length; i++) {
            LockedStake memory thisStake = lockedStakes[account][i];
            uint256 lock_multiplier = thisStake.lock_multiplier;
            if (thisStake.ending_timestamp <= block.timestamp){
                lock_multiplier = MULTIPLIER_PRECISION;
            }
            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = liquidity.mul(lock_multiplier.add(midpoint_vefxs_multiplier)).div(MULTIPLIER_PRECISION);
            new_combined_weight = new_combined_weight.add(combined_boosted_amount);
        }
    }
    function rewardPerToken() public view returns (uint256, uint256) {
        if (_total_liquidity_locked == 0 || _total_combined_weight == 0) {
            return (rewardPerTokenStored0, rewardPerTokenStored1);
        }
        else {
            return (
                rewardPerTokenStored0.add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate0).mul(1e18).div(_total_combined_weight)
                ),
                rewardPerTokenStored1.add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate1).mul(1e18).div(_total_combined_weight)
                )
            );
        }
    }
    function earned(address account) public view returns (uint256, uint256) {
        (uint256 rew_per_token0, uint256 rew_per_token1) = rewardPerToken();
        if (_combined_weights[account] == 0){
            return (0, 0);
        }
        return (
            (_combined_weights[account].mul(rew_per_token0.sub(userRewardPerTokenPaid0[account]))).div(1e18).add(rewards0[account]),
            (_combined_weights[account].mul(rew_per_token1.sub(userRewardPerTokenPaid1[account]))).div(1e18).add(rewards1[account])
        );
    }
    function getRewardForDuration() external view returns (uint256, uint256) {
        return (
            rewardRate0.mul(rewardsDuration),
            rewardRate1.mul(rewardsDuration)
        );
    }
    function _updateRewardAndBalance(address account, bool sync_too) internal {
        if (sync_too){
            sync();
        }
        if (account != address(0)) {
            (
                uint256 old_combined_weight,
                uint256 new_vefxs_multiplier,
                uint256 new_combined_weight
            ) = calcCurCombinedWeight(account);
            _syncEarned(account);
            _vefxsMultiplierStored[account] = new_vefxs_multiplier;
            if (new_combined_weight >= old_combined_weight) {
                uint256 weight_diff = new_combined_weight.sub(old_combined_weight);
                _total_combined_weight = _total_combined_weight.add(weight_diff);
                _combined_weights[account] = old_combined_weight.add(weight_diff);
            } else {
                uint256 weight_diff = old_combined_weight.sub(new_combined_weight);
                _total_combined_weight = _total_combined_weight.sub(weight_diff);
                _combined_weights[account] = old_combined_weight.sub(weight_diff);
            }
        }
    }
    function _syncEarned(address account) internal {
        if (account != address(0)) {
            (uint256 earned0, uint256 earned1) = earned(account);
            rewards0[account] = earned0;
            rewards1[account] = earned1;
            userRewardPerTokenPaid0[account] = rewardPerTokenStored0;
            userRewardPerTokenPaid1[account] = rewardPerTokenStored1;
        }
    }
    function stakerAllowMigrator(address migrator_address) external {
        require(valid_migrators[migrator_address], "Invalid migrator address");
        staker_allowed_migrators[msg.sender][migrator_address] = true;
    }
    function stakerDisallowMigrator(address migrator_address) external {
        delete staker_allowed_migrators[msg.sender][migrator_address];
    }
    function stakeLocked(uint256 liquidity, uint256 secs) nonReentrant public {
        _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
    }
    function _stakeLocked(
        address staker_address,
        address source_address,
        uint256 liquidity,
        uint256 secs,
        uint256 start_timestamp
    ) internal updateRewardAndBalance(staker_address, true) {
        require(!stakingPaused || valid_migrators[msg.sender] == true, "Staking paused or in migration");
        require(liquidity > 0, "Must stake more than zero");
        require(greylist[staker_address] == false, "Address has been greylisted");
        require(secs >= lock_time_min, "Minimum stake time not met");
        require(secs <= lock_time_for_max_multiplier,"Trying to lock for too long");
        uint256 lock_multiplier = lockMultiplier(secs);
        bytes32 kek_id = keccak256(abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address]));
        lockedStakes[staker_address].push(LockedStake(
            kek_id,
            start_timestamp,
            liquidity,
            start_timestamp.add(secs),
            lock_multiplier
        ));
        TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);
        _total_liquidity_locked = _total_liquidity_locked.add(liquidity);
        _locked_liquidity[staker_address] = _locked_liquidity[staker_address].add(liquidity);
        _updateRewardAndBalance(staker_address, false);
        emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);
    }
    function withdrawLocked(bytes32 kek_id) nonReentrant public {
        require(withdrawalsPaused == false, "Withdrawals paused");
        _withdrawLocked(msg.sender, msg.sender, kek_id);
    }
    function _withdrawLocked(address staker_address, address destination_address, bytes32 kek_id) internal  {
        _getReward(staker_address, destination_address);
        LockedStake memory thisStake;
        thisStake.liquidity = 0;
        uint theArrayIndex;
        for (uint i = 0; i < lockedStakes[staker_address].length; i++){
            if (kek_id == lockedStakes[staker_address][i].kek_id){
                thisStake = lockedStakes[staker_address][i];
                theArrayIndex = i;
                break;
            }
        }
        require(thisStake.kek_id == kek_id, "Stake not found");
        require(block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true || valid_migrators[msg.sender] == true, "Stake is still locked!");
        uint256 liquidity = thisStake.liquidity;
        if (liquidity > 0) {
            _total_liquidity_locked = _total_liquidity_locked.sub(liquidity);
            _locked_liquidity[staker_address] = _locked_liquidity[staker_address].sub(liquidity);
            delete lockedStakes[staker_address][theArrayIndex];
            _updateRewardAndBalance(staker_address, false);
            stakingToken.transfer(destination_address, liquidity);
            emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
        }
    }
    function getReward() external nonReentrant returns (uint256, uint256) {
        require(rewardsCollectionPaused == false,"Rewards collection paused");
        return _getReward(msg.sender, msg.sender);
    }
    function _getReward(address rewardee, address destination_address) internal updateRewardAndBalance(rewardee, true) returns (uint256 reward0, uint256 reward1) {
        reward0 = rewards0[rewardee];
        reward1 = rewards1[rewardee];
        if (reward0 > 0) {
            rewards0[rewardee] = 0;
            rewardsToken0.transfer(destination_address, reward0);
            emit RewardPaid(rewardee, reward0, address(rewardsToken0), destination_address);
        }
            if (reward1 > 0) {
                rewards1[rewardee] = 0;
                rewardsToken1.transfer(destination_address, reward1);
                emit RewardPaid(rewardee, reward1, address(rewardsToken1), destination_address);
            }
    }
    function retroCatchUp() internal {
        require(block.timestamp > periodFinish, "Period has not expired yet!");
        uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / rewardsDuration;
        uint balance0 = rewardsToken0.balanceOf(address(this));
        uint balance1 = rewardsToken1.balanceOf(address(this));
        require(rewardRate0.mul(rewardsDuration).mul(num_periods_elapsed + 1) <= balance0, "Not enough FXS available");
        if (token1_rewards_on){
            require(rewardRate1.mul(rewardsDuration).mul(num_periods_elapsed + 1) <= balance1, "Not enough token1 available for rewards!");
        }
        periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(rewardsDuration));
        (uint256 reward0, uint256 reward1) = rewardPerToken();
        rewardPerTokenStored0 = reward0;
        rewardPerTokenStored1 = reward1;
        lastUpdateTime = lastTimeRewardApplicable();
        emit RewardsPeriodRenewed(address(stakingToken));
    }
    function sync() public {
        if (block.timestamp > periodFinish) {
            retroCatchUp();
        }
        else {
            (uint256 reward0, uint256 reward1) = rewardPerToken();
            rewardPerTokenStored0 = reward0;
            rewardPerTokenStored1 = reward1;
            lastUpdateTime = lastTimeRewardApplicable();
        }
    }
    function migrator_stakeLocked_for(address staker_address, uint256 amount, uint256 secs, uint256 start_timestamp) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        _stakeLocked(staker_address, msg.sender, amount, secs, start_timestamp);
    }
    function migrator_withdraw_locked(address staker_address, bytes32 kek_id) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        _withdrawLocked(staker_address, msg.sender, kek_id);
    }
    function addMigrator(address migrator_address) external onlyByOwnGov {
        valid_migrators[migrator_address] = true;
    }
    function removeMigrator(address migrator_address) external onlyByOwnGov {
        require(valid_migrators[migrator_address] == true, "Address nonexistant");
        delete valid_migrators[migrator_address];
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        if(!migrationsOn){
            require(tokenAddress != address(stakingToken), "Not in migration");
        }
        ERC20(tokenAddress).transfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    function setRewardsDuration(uint256 _rewardsDuration) external onlyByOwnGovCtrlr {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Reward period incomplete"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    function setMultipliers(uint256 _lock_max_multiplier, uint256 _vefxs_max_multiplier, uint256 _vefxs_per_frax_for_max_boost) external onlyByOwnGov {
        require(_lock_max_multiplier >= MULTIPLIER_PRECISION, "Mult must be >= MULTIPLIER_PRECISION");
        require(_vefxs_max_multiplier >= 0, "veFXS mul must be >= 0");
        require(_vefxs_per_frax_for_max_boost > 0, "veFXS pct max must be >= 0");
        lock_max_multiplier = _lock_max_multiplier;
        vefxs_max_multiplier = _vefxs_max_multiplier;
        vefxs_per_frax_for_max_boost = _vefxs_per_frax_for_max_boost;
        emit MaxVeFXSMultiplier(vefxs_max_multiplier);
        emit LockedStakeMaxMultiplierUpdated(lock_max_multiplier);
        emit veFXSPerFraxForMaxBoostUpdated(vefxs_per_frax_for_max_boost);
    }
    function setLockedStakeTimeForMinAndMaxMultiplier(uint256 _lock_time_for_max_multiplier, uint256 _lock_time_min) external onlyByOwnGov {
        require(_lock_time_for_max_multiplier >= 1, "Mul max time must be >= 1");
        require(_lock_time_min >= 1, "Mul min time must be >= 1");
        lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
        lock_time_min = _lock_time_min;
        emit LockedStakeTimeForMaxMultiplier(lock_time_for_max_multiplier);
        emit LockedStakeMinTime(_lock_time_min);
    }
    function greylistAddress(address _address) external onlyByOwnGov {
        greylist[_address] = !(greylist[_address]);
    }
    function unlockStakes() external onlyByOwnGov {
        stakesUnlocked = !stakesUnlocked;
    }
    function toggleMigrations() external onlyByOwnGov {
        migrationsOn = !migrationsOn;
    }
    function toggleStaking() external onlyByOwnGov {
        stakingPaused = !stakingPaused;
    }
    function toggleWithdrawals() external onlyByOwnGov {
        withdrawalsPaused = !withdrawalsPaused;
    }
    function toggleRewardsCollection() external onlyByOwnGov {
        rewardsCollectionPaused = !rewardsCollectionPaused;
    }
    function setRewardRates(uint256 _new_rate0, uint256 _new_rate1, bool sync_too) external onlyByOwnGovCtrlr {
        rewardRate0 = _new_rate0;
        rewardRate1 = _new_rate1;
        if (sync_too){
            sync();
        }
    }
    function toggleToken1Rewards() external onlyByOwnGov {
        if (token1_rewards_on) {
            rewardRate1 = 0;
        }
        token1_rewards_on = !token1_rewards_on;
    }
    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }
    function setController(address _controller_address) external onlyByOwnGov {
        controller_address = _controller_address;
    }
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
    event WithdrawLocked(address indexed user, uint256 amount, bytes32 kek_id, address destination_address);
    event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event RewardsPeriodRenewed(address token);
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
    event LockedStakeTimeForMaxMultiplier(uint256 secs);
    event LockedStakeMinTime(uint256 secs);
    event MaxVeFXSMultiplier(uint256 multiplier);
    event veFXSPerFraxForMaxBoostUpdated(uint256 scale_factor);
}