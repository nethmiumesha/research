pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./BaseRewardEscrowV2.sol";
import "./interfaces/IRewardEscrow.sol";
import "./interfaces/ISystemStatus.sol";
contract RewardEscrowV2 is BaseRewardEscrowV2 {
    mapping(address => uint256) public totalBalancePendingMigration;
    uint public migrateEntriesThresholdAmount = SafeDecimalMath.unit() * 1000;
    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM = "SynthetixBridgeToOptimism";
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    constructor(address _owner, address _resolver) public BaseRewardEscrowV2(_owner, _resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseRewardEscrowV2.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM;
        newAddresses[1] = CONTRACT_REWARD_ESCROW;
        newAddresses[2] = CONTRACT_SYSTEMSTATUS;
        return combineArrays(existingAddresses, newAddresses);
    }
    function synthetixBridgeToOptimism() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM);
    }
    function oldRewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARD_ESCROW));
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    uint internal constant TIME_INDEX = 0;
    uint internal constant QUANTITY_INDEX = 1;
    function setMigrateEntriesThresholdAmount(uint amount) external onlyOwner {
        migrateEntriesThresholdAmount = amount;
        emit MigrateEntriesThresholdAmountUpdated(amount);
    }
    function migrateVestingSchedule(address addressToMigrate) external systemActive {
        require(totalBalancePendingMigration[addressToMigrate] > 0, "No escrow migration pending");
        require(totalEscrowedAccountBalance[addressToMigrate] > 0, "Address escrow balance is 0");
        if (totalBalancePendingMigration[addressToMigrate] <= migrateEntriesThresholdAmount) {
            _importVestingEntry(
                addressToMigrate,
                VestingEntries.VestingEntry({
                    endTime: uint64(block.timestamp),
                    escrowAmount: totalBalancePendingMigration[addressToMigrate]
                })
            );
            delete totalBalancePendingMigration[addressToMigrate];
        } else {
            uint numEntries = oldRewardEscrow().numVestingEntries(addressToMigrate);
            for (uint i = 1; i <= numEntries; i++) {
                uint[2] memory vestingSchedule = oldRewardEscrow().getVestingScheduleEntry(addressToMigrate, numEntries - i);
                uint time = vestingSchedule[TIME_INDEX];
                uint amount = vestingSchedule[QUANTITY_INDEX];
                if (time < block.timestamp) {
                    break;
                }
                _importVestingEntry(
                    addressToMigrate,
                    VestingEntries.VestingEntry({endTime: uint64(time), escrowAmount: amount})
                );
                totalBalancePendingMigration[addressToMigrate] = totalBalancePendingMigration[addressToMigrate].sub(amount);
            }
        }
    }
    function importVestingSchedule(address[] calldata accounts, uint256[] calldata escrowAmounts)
        external
        onlyDuringSetup
        onlyOwner
    {
        require(accounts.length == escrowAmounts.length, "Account and escrowAmounts Length mismatch");
        for (uint i = 0; i < accounts.length; i++) {
            address addressToMigrate = accounts[i];
            uint256 escrowAmount = escrowAmounts[i];
            require(totalEscrowedAccountBalance[addressToMigrate] > 0, "Address escrow balance is 0");
            require(totalBalancePendingMigration[addressToMigrate] > 0, "No escrow migration pending");
            _importVestingEntry(
                addressToMigrate,
                VestingEntries.VestingEntry({endTime: uint64(block.timestamp), escrowAmount: escrowAmount})
            );
            totalBalancePendingMigration[addressToMigrate] = totalBalancePendingMigration[addressToMigrate].sub(
                escrowAmount
            );
            emit ImportedVestingSchedule(addressToMigrate, block.timestamp, escrowAmount);
        }
    }
    function migrateAccountEscrowBalances(
        address[] calldata accounts,
        uint256[] calldata escrowBalances,
        uint256[] calldata vestedBalances
    ) external onlyDuringSetup onlyOwner {
        require(accounts.length == escrowBalances.length, "Number of accounts and balances don't match");
        require(accounts.length == vestedBalances.length, "Number of accounts and vestedBalances don't match");
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint escrowedAmount = escrowBalances[i];
            uint vestedAmount = vestedBalances[i];
            require(totalBalancePendingMigration[account] == 0, "Account migration is pending already");
            totalEscrowedBalance = totalEscrowedBalance.add(escrowedAmount);
            totalEscrowedAccountBalance[account] = totalEscrowedAccountBalance[account].add(escrowedAmount);
            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(vestedAmount);
            totalBalancePendingMigration[account] = escrowedAmount;
            emit MigratedAccountEscrow(account, escrowedAmount, vestedAmount, now);
        }
    }
    function _importVestingEntry(address account, VestingEntries.VestingEntry memory entry) internal {
        uint entryID = BaseRewardEscrowV2._addVestingEntry(account, entry);
        emit ImportedVestingEntry(account, entryID, entry.escrowAmount, entry.endTime);
    }
    function burnForMigration(address account, uint[] calldata entryIDs)
        external
        onlySynthetixBridge
        returns (uint256 escrowedAccountBalance, VestingEntries.VestingEntry[] memory vestingEntries)
    {
        require(entryIDs.length > 0, "Entry IDs required");
        vestingEntries = new VestingEntries.VestingEntry[](entryIDs.length);
        for (uint i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry storage entry = vestingSchedules[account][entryIDs[i]];
            if (entry.escrowAmount > 0) {
                vestingEntries[i] = entry;
                escrowedAccountBalance = escrowedAccountBalance.add(entry.escrowAmount);
                delete vestingSchedules[account][entryIDs[i]];
            }
        }
        if (escrowedAccountBalance > 0) {
            _reduceAccountEscrowBalances(account, escrowedAccountBalance);
            IERC20(address(synthetix())).transfer(synthetixBridgeToOptimism(), escrowedAccountBalance);
        }
        emit BurnedForMigrationToL2(account, entryIDs, escrowedAccountBalance, block.timestamp);
        return (escrowedAccountBalance, vestingEntries);
    }
    modifier onlySynthetixBridge() {
        require(msg.sender == synthetixBridgeToOptimism(), "Can only be invoked by SynthetixBridgeToOptimism contract");
        _;
    }
    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }
    event MigratedAccountEscrow(address indexed account, uint escrowedAmount, uint vestedAmount, uint time);
    event ImportedVestingSchedule(address indexed account, uint time, uint escrowAmount);
    event BurnedForMigrationToL2(address indexed account, uint[] entryIDs, uint escrowedAmountMigrated, uint time);
    event ImportedVestingEntry(address indexed account, uint entryID, uint escrowAmount, uint endTime);
    event MigrateEntriesThresholdAmountUpdated(uint newAmount);
}