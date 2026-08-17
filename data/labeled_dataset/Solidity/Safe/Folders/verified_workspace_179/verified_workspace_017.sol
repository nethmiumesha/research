pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./dex/DexAggregatorInterface.sol";
contract XOLEStorage {
    string public name = 'xOLE';
    string public symbol = 'xOLE';
    uint8 public constant decimals = 18;
    uint public supply;
    mapping(address => mapping(address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    mapping(address => LockedBalance) public locked;
    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history;
    mapping(address => Point[1000000000]) public user_point_history;
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes;
    DexAggregatorInterface dexAgg;
    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
    }
    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }
    struct Vars {
        uint256 _epoch;
        uint256 user_epoch;
    }
    address ZERO_ADDRESS = address(0);
    int128 constant DEPOSIT_FOR_TYPE = 0;
    int128 constant CREATE_LOCK_TYPE = 1;
    int128 constant INCREASE_LOCK_AMOUNT = 2;
    int128 constant INCREASE_UNLOCK_TIME = 3;
    uint256 constant WEEK = 7 * 86400;
    uint256 constant MAXTIME = 4 * 365 * 86400;
    uint256 constant MULTIPLIER = 10 ** 18;
    IERC20 oleToken;
    address public dev;
    uint public devFund;
    uint public totalStaked;
    mapping(address => uint) public stakedBalances;
    uint public devFundRatio;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint public totalRewarded;
    uint public withdrewReward;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    event RewardAdded(address fromToken, uint convertAmount, uint reward);
    event RewardConvert(address fromToken, address toToken, uint convertAmount, uint returnAmount);
    event Deposit (
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        int128 type_,
        uint256 ts
    );
    event Withdraw (
        address indexed provider,
        uint256 value,
        uint256 ts
    );
    event Supply (
        uint256 prevSupply,
        uint256 supply
    );
    event RewardPaid (
        address paidTo,
        uint256 amount
    );
}
interface XOLEInterface {
    function convertToSharingToken(uint amount, uint minBuyAmount, bytes memory data) external;
    function withdrawDevFund() external;
    function earned(address account) external view returns (uint);
    function withdrawReward() external;
    function setDevFundRatio(uint newRatio) external;
    function setDev(address newDev) external;
    function setDexAgg(DexAggregatorInterface newDexAgg) external;
    event CommitOwnership (address admin);
    event ApplyOwnership (address admin);
    function get_last_user_slope(address addr) external view returns (int128);
    function user_point_history_ts(address _addr, uint256 _idx) external view returns (uint256);
    function locked__end(address _addr) external view returns (uint256);
    function checkpoint() external;
    function deposit_for(address _addr, uint256 _value) external;
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);
    function totalSupply(uint256 t) external view returns (uint256);
    function totalSupplyAt(uint256 _block) external view returns (uint256);
}