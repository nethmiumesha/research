pragma solidity ^0.5.16;
import "./Owned.sol";
import "./interfaces/IRewardEscrow.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/ISynthetix.sol";
contract RewardEscrow is Owned, IRewardEscrow {
    using SafeMath for uint;
    ISynthetix public synthetix;
    IFeePool public feePool;
    mapping(address => uint[2][]) public vestingSchedules;
    mapping(address => uint) public totalEscrowedAccountBalance;
    mapping(address => uint) public totalVestedAccountBalance;
    uint public totalEscrowedBalance;
    uint internal constant TIME_INDEX = 0;
    uint internal constant QUANTITY_INDEX = 1;
    uint public constant MAX_VESTING_ENTRIES = 52 * 5;
    constructor(
        address _owner,
        ISynthetix _synthetix,
        IFeePool _feePool
    ) public Owned(_owner) {
        synthetix = _synthetix;
        feePool = _feePool;
    }
    function setSynthetix(ISynthetix _synthetix) external onlyOwner {
        synthetix = _synthetix;
        emit SynthetixUpdated(address(_synthetix));
    }
    function setFeePool(IFeePool _feePool) external onlyOwner {
        feePool = _feePool;
        emit FeePoolUpdated(address(_feePool));
    }
    function balanceOf(address account) public view returns (uint) {
        return totalEscrowedAccountBalance[account];
    }
    function _numVestingEntries(address account) internal view returns (uint) {
        return vestingSchedules[account].length;
    }
    function numVestingEntries(address account) external view returns (uint) {
        return vestingSchedules[account].length;
    }
    function getVestingScheduleEntry(address account, uint index) public view returns (uint[2] memory) {
        return vestingSchedules[account][index];
    }
    function getVestingTime(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[TIME_INDEX];
    }
    function getVestingQuantity(address account, uint index) public view returns (uint) {
        return getVestingScheduleEntry(account, index)[QUANTITY_INDEX];
    }
    function getNextVestingIndex(address account) public view returns (uint) {
        uint len = _numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }
    function getNextVestingEntry(address account) public view returns (uint[2] memory) {
        uint index = getNextVestingIndex(account);
        if (index == _numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }
    function getNextVestingTime(address account) external view returns (uint) {
        return getNextVestingEntry(account)[TIME_INDEX];
    }
    function getNextVestingQuantity(address account) external view returns (uint) {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }
    function checkAccountSchedule(address account) public view returns (uint[520] memory) {
        uint[520] memory _result;
        uint schedules = _numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = getVestingScheduleEntry(account, i);
            _result[i * 2] = pair[0];
            _result[i * 2 + 1] = pair[1];
        }
        return _result;
    }
    function _appendVestingEntry(address account, uint quantity) internal {
        require(quantity != 0, "Quantity cannot be zero");
        totalEscrowedBalance = totalEscrowedBalance.add(quantity);
        require(
            totalEscrowedBalance <= IERC20(address(synthetix)).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");
        uint time = now + 52 weeks;
        if (scheduleLength == 0) {
            totalEscrowedAccountBalance[account] = quantity;
        } else {
            require(
                getVestingTime(account, scheduleLength - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );
            totalEscrowedAccountBalance[account] = totalEscrowedAccountBalance[account].add(quantity);
        }
        vestingSchedules[account].push([time, quantity]);
        emit VestingEntryCreated(account, now, quantity);
    }
    function appendVestingEntry(address account, uint quantity) external onlyFeePool {
        _appendVestingEntry(account, quantity);
    }
    function vest() external {
        uint numEntries = _numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty > 0) {
                vestingSchedules[msg.sender][i] = [0, 0];
                total = total.add(qty);
            }
        }
        if (total != 0) {
            totalEscrowedBalance = totalEscrowedBalance.sub(total);
            totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);
            IERC20(address(synthetix)).transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }
    modifier onlyFeePool() {
        bool isFeePool = msg.sender == address(feePool);
        require(isFeePool, "Only the FeePool contracts can perform this action");
        _;
    }
    event SynthetixUpdated(address newSynthetix);
    event FeePoolUpdated(address newFeePool);
    event Vested(address indexed beneficiary, uint time, uint value);
    event VestingEntryCreated(address indexed beneficiary, uint time, uint value);
}