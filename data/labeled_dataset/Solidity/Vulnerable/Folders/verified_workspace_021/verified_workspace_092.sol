pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./BaseSynthetixBridge.sol";
import "./interfaces/ISynthetixBridgeToBase.sol";
import "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";
import "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";
contract SynthetixBridgeToBase is BaseSynthetixBridge, ISynthetixBridgeToBase, iOVM_L2DepositedToken {
    bytes32 private constant CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM = "base:SynthetixBridgeToOptimism";
    function CONTRACT_NAME() public pure returns (bytes32) {
        return "SynthetixBridgeToBase";
    }
    constructor(address _owner, address _resolver) public BaseSynthetixBridge(_owner, _resolver) {}
    function synthetixBridgeToOptimism() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM);
    }
    function counterpart() internal view returns (address) {
        return synthetixBridgeToOptimism();
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseSynthetixBridge.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    function withdraw(uint amount) external requireInitiationActive {
        _initiateWithdraw(msg.sender, amount);
    }
    function withdrawTo(address to, uint amount) external requireInitiationActive {
        _initiateWithdraw(to, amount);
    }
    function _initiateWithdraw(address to, uint amount) private {
        require(synthetix().transferableSynthetix(msg.sender) >= amount, "Not enough transferable SNX");
        synthetix().burnSecondary(msg.sender, amount);
        iOVM_L1TokenGateway bridgeToOptimism;
        bytes memory messageData = abi.encodeWithSelector(bridgeToOptimism.finalizeWithdrawal.selector, to, amount);
        messenger().sendMessage(
            synthetixBridgeToOptimism(),
            messageData,
            uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Withdrawal))
        );
        emit iOVM_L2DepositedToken.WithdrawalInitiated(msg.sender, to, amount);
    }
    function finalizeEscrowMigration(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external onlyCounterpart {
        IRewardEscrowV2 rewardEscrow = rewardEscrowV2();
        synthetix().mintSecondary(address(rewardEscrow), escrowedAmount);
        rewardEscrow.importVestingEntries(account, escrowedAmount, vestingEntries);
        emit ImportedVestingEntries(account, escrowedAmount, vestingEntries);
    }
    function finalizeDeposit(address to, uint256 amount) external onlyCounterpart {
        synthetix().mintSecondary(to, amount);
        emit iOVM_L2DepositedToken.DepositFinalized(to, amount);
    }
    function finalizeRewardDeposit(address from, uint256 amount) external onlyCounterpart {
        synthetix().mintSecondaryRewards(amount);
        emit RewardDepositFinalized(from, amount);
    }
    function finalizeFeePeriodClose(uint256 snxBackedAmount, uint256 totalDebtShares) external onlyCounterpart {
        feePool().closeSecondary(snxBackedAmount, totalDebtShares);
        emit FeePeriodCloseFinalized(snxBackedAmount, totalDebtShares);
    }
    event ImportedVestingEntries(
        address indexed account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] vestingEntries
    );
    event RewardDepositFinalized(address from, uint256 amount);
    event FeePeriodCloseFinalized(uint snxBackedAmount, uint totalDebtShares);
}