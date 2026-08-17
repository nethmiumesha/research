pragma solidity ^0.5.16;
import "./Owned.sol";
import "./LimitedSetup.sol";
import "./interfaces/IHasBalance.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISynthetix.sol";
contract SynthetixEscrow is Owned, LimitedSetup(8 weeks), IHasBalance {
    using SafeMath for uint;
    ISynthetix public synthetix;
    mapping(address => uint[2][]) public vestingSchedules;
    mapping(address => uint) public totalVestedAccountBalance;
    uint public totalVestedBalance;
    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;
    uint public constant MAX_VESTING_ENTRIES = 20;
    constructor(address _owner, ISynthetix _synthetix) public Owned(_owner) {
        synthetix = _synthetix;
    }
    function setSynthetix(ISynthetix _synthetix) external onlyOwner {
        synthetix = _synthetix;
        emit SynthetixUpdated(address(_synthetix));
    }
    function balanceOf(address account) public view returns (uint) {
        return totalVestedAccountBalance[account];
    }
    function numVestingEntries(address account) public view returns (uint) {
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
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }
    function getNextVestingEntry(address account) public view returns (uint[2] memory) {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
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
    function purgeAccount(address account) external onlyOwner onlyDuringSetup {
        delete vestingSchedules[account];
        totalVestedBalance = totalVestedBalance.sub(totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }
    function appendVestingEntry(
        address account,
        uint time,
        uint quantity
    ) public onlyOwner onlyDuringSetup {
        require(now < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");
        totalVestedBalance = totalVestedBalance.add(quantity);
        require(
            totalVestedBalance <= IERC20(address(synthetix)).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");
        if (scheduleLength == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
            require(
                getVestingTime(account, numVestingEntries(account) - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );
            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
        }
        vestingSchedules[account].push([time, quantity]);
    }
    function addVestingSchedule(
        address account,
        uint[] calldata times,
        uint[] calldata quantities
    ) external onlyOwner onlyDuringSetup {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }
    }
    function vest() external {
        uint numEntries = numVestingEntries(msg.sender);
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
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);
            IERC20(address(synthetix)).transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }
    event SynthetixUpdated(address newSynthetix);
    event Vested(address indexed beneficiary, uint time, uint value);
}