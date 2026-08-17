pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;
import "../Math/Math.sol";
import "../Math/SafeMath.sol";
import "../ERC20/ERC20.sol";
import "../Curve/IveFXS.sol";
import "../ERC20/SafeERC20.sol";
import '../Uniswap/TransferHelper.sol';
import "../Misc_AMOs/gelato/IGUniPool.sol";
import '../Misc_AMOs/stakedao/IOpynPerpVault.sol';
import "../Curve/IFraxGaugeController.sol";
import "../Curve/IFraxGaugeFXSRewardsDistributor.sol";
import "../Utils/ReentrancyGuard.sol";
import "./Owned.sol";
contract StakingRewardsMultiGauge is Owned, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    IveFXS private veFXS = IveFXS(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);
    IOpynPerpVault public stakingToken;
    IFraxGaugeFXSRewardsDistributor public rewards_distributor;
    address private constant frax_address = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    uint256 private constant MULTIPLIER_PRECISION = 1e18;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public lock_max_multiplier = uint256(3e18);
    uint256 public lock_time_for_max_multiplier = 3 * 365 * 86400;
    uint256 public lock_time_min = 86400;
    uint256 public vefxs_per_frax_for_max_boost = uint256(4e18);
    uint256 public vefxs_max_multiplier = uint256(2e18);
    mapping(address => uint256) private _vefxsMultiplierStored;
    mapping(address => address) public rewardManagers;
    address[] public rewardTokens;
    address[] public gaugeControllers;
    uint256[] public rewardRatesManual;
    string[] public rewardSymbols;
    mapping(address => uint256) public rewardTokenAddrToIdx;
    uint256 public rewardsDuration = 604800;
    uint256[] private rewardsPerTokenStored;
    mapping(address => mapping(uint256 => uint256)) private userRewardsPerTokenPaid;
    mapping(address => mapping(uint256 => uint256)) private rewards;
    mapping(address => uint256) private lastRewardClaimTime;
    uint256[] private last_gauge_relative_weights;
    uint256[] private last_gauge_time_totals;
    uint256 private _total_liquidity_locked;
    uint256 private _total_combined_weight;
    mapping(address => uint256) private _locked_liquidity;
    mapping(address => uint256) private _combined_weights;
    mapping(address => bool) public valid_migrators;
    mapping(address => mapping(address => bool)) public staker_allowed_migrators;
    bool frax_is_token0;
    mapping(address => LockedStake[]) private lockedStakes;
    mapping(address => bool) public greylist;
    bool public stakesUnlocked;
    bool public migrationsOn;
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
    modifier onlyByOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    modifier onlyTknMgrs(address reward_token_address) {
        require(msg.sender == owner || isTokenManagerFor(msg.sender, reward_token_address), "Not owner or tkn mgr");
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
        address _stakingToken,
        address _rewards_distributor_address,
        string[] memory _rewardSymbols,
        address[] memory _rewardTokens,
        address[] memory _rewardManagers,
        uint256[] memory _rewardRatesManual,
        address[] memory _gaugeControllers
    ) Owned(_owner){
        stakingToken = IOpynPerpVault(_stakingToken);
        rewards_distributor = IFraxGaugeFXSRewardsDistributor(_rewards_distributor_address);
        rewardTokens = _rewardTokens;
        gaugeControllers = _gaugeControllers;
        rewardRatesManual = _rewardRatesManual;
        rewardSymbols = _rewardSymbols;
        for (uint256 i = 0; i < _rewardTokens.length; i++){
            rewardTokenAddrToIdx[_rewardTokens[i]] = i;
            rewardsPerTokenStored.push(0);
            rewardManagers[_rewardTokens[i]] = _rewardManagers[i];
            last_gauge_relative_weights.push(0);
            last_gauge_time_totals.push(0);
        }
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
    function fraxPerLPToken() public view returns (uint256) {
        uint256 frax_per_lp_token;
        {
           uint256 frax3crv_held = stakingToken.totalUnderlyingControlled();
           frax_per_lp_token = (frax3crv_held.mul(1e18).div(stakingToken.totalSupply())) / 2;
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
            if (thisStake.ending_timestamp <= block.timestamp) {
                if (lastRewardClaimTime[account] < thisStake.ending_timestamp){
                    uint256 time_before_expiry = (thisStake.ending_timestamp).sub(lastRewardClaimTime[account]);
                    uint256 time_after_expiry = (block.timestamp).sub(thisStake.ending_timestamp);
                    uint256 numerator = ((lock_multiplier).mul(time_before_expiry)).add(((MULTIPLIER_PRECISION).mul(time_after_expiry)));
                    lock_multiplier = numerator.div(time_before_expiry.add(time_after_expiry));
                }
                else {
                    lock_multiplier = MULTIPLIER_PRECISION;
                }
            }
            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = liquidity.mul(lock_multiplier.add(midpoint_vefxs_multiplier)).div(MULTIPLIER_PRECISION);
            new_combined_weight = new_combined_weight.add(combined_boosted_amount);
        }
    }
    function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
        return lockedStakes[account];
    }
    function getRewardSymbols() external view returns (string[] memory) {
        return rewardSymbols;
    }
    function getAllRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
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
    function rewardRates(uint256 token_idx) public view returns (uint256 rwd_rate) {
        address gauge_controller_address = gaugeControllers[token_idx];
        if (gauge_controller_address != address(0)) {
            rwd_rate = (IFraxGaugeController(gauge_controller_address).global_emission_rate()).mul(last_gauge_relative_weights[token_idx]).div(1e18);
        }
        else {
            rwd_rate = rewardRatesManual[token_idx];
        }
    }
    function rewardsPerToken() public view returns (uint256[] memory newRewardsPerTokenStored) {
        if (_total_liquidity_locked == 0 || _total_combined_weight == 0) {
            return rewardsPerTokenStored;
        }
        else {
            newRewardsPerTokenStored = new uint256[](rewardTokens.length);
            for (uint256 i = 0; i < rewardsPerTokenStored.length; i++){
                newRewardsPerTokenStored[i] = rewardsPerTokenStored[i].add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates(i)).mul(1e18).div(_total_combined_weight)
                );
            }
            return newRewardsPerTokenStored;
        }
    }
    function earned(address account) public view returns (uint256[] memory new_earned) {
        uint256[] memory reward_arr = rewardsPerToken();
        new_earned = new uint256[](rewardTokens.length);
        if (_combined_weights[account] == 0){
            for (uint256 i = 0; i < rewardTokens.length; i++){
                new_earned[i] = 0;
            }
        }
        else {
            for (uint256 i = 0; i < rewardTokens.length; i++){
                new_earned[i] = (_combined_weights[account])
                    .mul(reward_arr[i].sub(userRewardsPerTokenPaid[account][i]))
                    .div(1e18)
                    .add(rewards[account][i]);
            }
        }
    }
    function getRewardForDuration() external view returns (uint256[] memory rewards_per_duration_arr) {
        rewards_per_duration_arr = new uint256[](rewardRatesManual.length);
        for (uint256 i = 0; i < rewardRatesManual.length; i++){
            rewards_per_duration_arr[i] = rewardRates(i).mul(rewardsDuration);
        }
    }
    function isTokenManagerFor(address caller_addr, address reward_token_addr) public view returns (bool){
        if (caller_addr == owner) return true;
        else if (rewardManagers[reward_token_addr] == caller_addr) return true;
        return false;
    }
    function stakerAllowMigrator(address migrator_address) external {
        require(valid_migrators[migrator_address], "Invalid migrator address");
        staker_allowed_migrators[msg.sender][migrator_address] = true;
    }
    function stakerDisallowMigrator(address migrator_address) external {
        delete staker_allowed_migrators[msg.sender][migrator_address];
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
            uint256[] memory earned_arr = earned(account);
            for (uint256 i = 0; i < earned_arr.length; i++){
                rewards[account][i] = earned_arr[i];
            }
            for (uint256 i = 0; i < earned_arr.length; i++){
                userRewardsPerTokenPaid[account][i] = rewardsPerTokenStored[i];
            }
        }
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
        require(!stakingPaused, "Staking paused");
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
        if (lastRewardClaimTime[staker_address] == 0) lastRewardClaimTime[staker_address] = block.timestamp;
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
        for (uint256 i = 0; i < lockedStakes[staker_address].length; i++){
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
    function getReward() external nonReentrant returns (uint256[] memory) {
        require(rewardsCollectionPaused == false,"Rewards collection paused");
        return _getReward(msg.sender, msg.sender);
    }
    function _getReward(address rewardee, address destination_address) internal updateRewardAndBalance(rewardee, true) returns (uint256[] memory rewards_before) {
        rewards_before = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++){
            rewards_before[i] = rewards[rewardee][i];
            rewards[rewardee][i] = 0;
            ERC20(rewardTokens[i]).transfer(destination_address, rewards_before[i]);
            emit RewardPaid(rewardee, rewards_before[i], rewardTokens[i], destination_address);
        }
        lastRewardClaimTime[rewardee] = block.timestamp;
    }
    function retroCatchUp() internal {
        rewards_distributor.distributeReward(address(this));
        uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / rewardsDuration;
        for (uint256 i = 0; i < rewardTokens.length; i++){
            require(rewardRates(i).mul(rewardsDuration).mul(num_periods_elapsed + 1) <= ERC20(rewardTokens[i]).balanceOf(address(this)), string(abi.encodePacked("Not enough reward tokens available: ", rewardTokens[i])) );
        }
        periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(rewardsDuration));
        _updateStoredRewardsAndTime();
        emit RewardsPeriodRenewed(address(stakingToken));
    }
    function _updateStoredRewardsAndTime() internal {
        uint256[] memory rewards_per_token = rewardsPerToken();
        for (uint256 i = 0; i < rewardsPerTokenStored.length; i++){
            rewardsPerTokenStored[i] = rewards_per_token[i];
        }
        lastUpdateTime = lastTimeRewardApplicable();
    }
    function sync_gauge_weights(bool force_update) public {
        for (uint256 i = 0; i < gaugeControllers.length; i++){
            address gauge_controller_address = gaugeControllers[i];
            if (gauge_controller_address != address(0)) {
                if (force_update || (block.timestamp > last_gauge_time_totals[i])){
                    last_gauge_relative_weights[i] = IFraxGaugeController(gauge_controller_address).gauge_relative_weight_write(address(this), block.timestamp);
                    last_gauge_time_totals[i] = IFraxGaugeController(gauge_controller_address).time_total();
                }
            }
        }
    }
    function sync() public {
        sync_gauge_weights(false);
        if (block.timestamp >= periodFinish) {
            retroCatchUp();
        }
        else {
            _updateStoredRewardsAndTime();
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
    function addMigrator(address migrator_address) external onlyByOwner {
        valid_migrators[migrator_address] = true;
    }
    function removeMigrator(address migrator_address) external onlyByOwner {
        require(valid_migrators[migrator_address] == true, "Address nonexistant");
        delete valid_migrators[migrator_address];
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyTknMgrs(tokenAddress) {
        bool isRewardToken = false;
        for (uint256 i = 0; i < rewardTokens.length; i++){
            if (rewardTokens[i] == tokenAddress) {
                isRewardToken = true;
                break;
            }
        }
        if (isRewardToken && rewardManagers[tokenAddress] == msg.sender){
            ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
            emit Recovered(msg.sender, tokenAddress, tokenAmount);
            return;
        }
        else if (!isRewardToken && (msg.sender == owner)){
            ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
            emit Recovered(msg.sender, tokenAddress, tokenAmount);
            return;
        }
        else {
            revert("No valid tokens to recover");
        }
    }
    function setRewardsDuration(uint256 _rewardsDuration) external onlyByOwner {
        require(_rewardsDuration >= 86400, "Rewards duration too short");
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Reward period incomplete"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    function setMultipliers(uint256 _lock_max_multiplier, uint256 _vefxs_max_multiplier, uint256 _vefxs_per_frax_for_max_boost) external onlyByOwner {
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
    function setLockedStakeTimeForMinAndMaxMultiplier(uint256 _lock_time_for_max_multiplier, uint256 _lock_time_min) external onlyByOwner {
        require(_lock_time_for_max_multiplier >= 1, "Mul max time must be >= 1");
        require(_lock_time_min >= 1, "Mul min time must be >= 1");
        lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
        lock_time_min = _lock_time_min;
        emit LockedStakeTimeForMaxMultiplier(lock_time_for_max_multiplier);
        emit LockedStakeMinTime(_lock_time_min);
    }
    function greylistAddress(address _address) external onlyByOwner {
        greylist[_address] = !(greylist[_address]);
    }
    function unlockStakes() external onlyByOwner {
        stakesUnlocked = !stakesUnlocked;
    }
    function toggleStaking() external onlyByOwner {
        stakingPaused = !stakingPaused;
    }
    function toggleMigrations() external onlyByOwner {
        migrationsOn = !migrationsOn;
    }
    function toggleWithdrawals() external onlyByOwner {
        withdrawalsPaused = !withdrawalsPaused;
    }
    function toggleRewardsCollection() external onlyByOwner {
        rewardsCollectionPaused = !rewardsCollectionPaused;
    }
    function setRewardRate(address reward_token_address, uint256 new_rate, bool sync_too) external onlyTknMgrs(reward_token_address) {
        rewardRatesManual[rewardTokenAddrToIdx[reward_token_address]] = new_rate;
        if (sync_too){
            sync();
        }
    }
    function setGaugeController(address reward_token_address, address _rewards_distributor_address, address _gauge_controller_address, bool sync_too) external onlyTknMgrs(reward_token_address) {
        gaugeControllers[rewardTokenAddrToIdx[reward_token_address]] = _gauge_controller_address;
        rewards_distributor = IFraxGaugeFXSRewardsDistributor(_rewards_distributor_address);
        if (sync_too){
            sync();
        }
    }
    function changeTokenManager(address reward_token_address, address new_manager_address) external onlyTknMgrs(reward_token_address) {
        rewardManagers[reward_token_address] = new_manager_address;
    }
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
    event WithdrawLocked(address indexed user, uint256 amount, bytes32 kek_id, address destination_address);
    event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address destination_address, address token, uint256 amount);
    event RewardsPeriodRenewed(address token);
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
    event LockedStakeTimeForMaxMultiplier(uint256 secs);
    event LockedStakeMinTime(uint256 secs);
    event MaxVeFXSMultiplier(uint256 multiplier);
    event veFXSPerFraxForMaxBoostUpdated(uint256 scale_factor);
}