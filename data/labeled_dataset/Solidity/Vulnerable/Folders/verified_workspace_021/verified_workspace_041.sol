pragma solidity >=0.4.24;
pragma experimental ABIEncoderV2;
import "./IRewardEscrowV2.sol";
interface ISynthetixBridgeToBase {
    function finalizeEscrowMigration(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external;
    function finalizeRewardDeposit(address from, uint amount) external;
    function finalizeFeePeriodClose(uint snxBackedDebt, uint debtSharesSupply) external;
}