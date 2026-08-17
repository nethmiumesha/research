pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./BaseSynthetixBridge.sol";
import "./interfaces/ISynthetixBridgeToOptimism.sol";
import "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/ISynthetixBridgeToBase.sol";
import "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";
contract SynthetixBridgeToOptimism is BaseSynthetixBridge, ISynthetixBridgeToOptimism, iOVM_L1TokenGateway {
    using SafeERC20 for IERC20;
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_REWARDSDISTRIBUTION = "RewardsDistribution";
    bytes32 private constant CONTRACT_OVM_SYNTHETIXBRIDGETOBASE = "ovm:SynthetixBridgeToBase";
    bytes32 private constant CONTRACT_SYNTHETIXBRIDGEESCROW = "SynthetixBridgeEscrow";
    uint8 private constant MAX_ENTRIES_MIGRATED_PER_MESSAGE = 26;
    function CONTRACT_NAME() public pure returns (bytes32) {
        return "SynthetixBridgeToOptimism";
    }
    constructor(address _owner, address _resolver) public BaseSynthetixBridge(_owner, _resolver) {}
    function synthetixERC20() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }
    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }
    function rewardsDistribution() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_REWARDSDISTRIBUTION);
    }
    function synthetixBridgeToBase() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_OVM_SYNTHETIXBRIDGETOBASE);
    }
    function synthetixBridgeEscrow() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_SYNTHETIXBRIDGEESCROW);
    }
    function hasZeroDebt() internal view {
        require(issuer().debtBalanceOf(msg.sender, "sUSD") == 0, "Cannot deposit or migrate with debt");
    }
    function counterpart() internal view returns (address) {
        return synthetixBridgeToBase();
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseSynthetixBridge.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](4);
        newAddresses[0] = CONTRACT_ISSUER;
        newAddresses[1] = CONTRACT_REWARDSDISTRIBUTION;
        newAddresses[2] = CONTRACT_OVM_SYNTHETIXBRIDGETOBASE;
        newAddresses[3] = CONTRACT_SYNTHETIXBRIDGEESCROW;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    modifier requireZeroDebt() {
        hasZeroDebt();
        _;
    }
    function deposit(uint256 amount) external requireInitiationActive requireZeroDebt {
        _initiateDeposit(msg.sender, amount);
    }
    function depositTo(address to, uint amount) external requireInitiationActive requireZeroDebt {
        _initiateDeposit(to, amount);
    }
    function migrateEscrow(uint256[][] memory entryIDs) public requireInitiationActive requireZeroDebt {
        _migrateEscrow(entryIDs);
    }
    function depositReward(uint amount) external requireInitiationActive {
        synthetixERC20().transferFrom(msg.sender, synthetixBridgeEscrow(), amount);
        _depositReward(msg.sender, amount);
    }
    function forwardTokensToEscrow(address token) external {
        IERC20 erc20 = IERC20(token);
        erc20.safeTransfer(synthetixBridgeEscrow(), erc20.balanceOf(address(this)));
    }
    function closeFeePeriod(uint snxBackedAmount, uint totalDebtShares) external requireInitiationActive {
        require(msg.sender == address(feePool()), "Only the fee pool can call this");
        ISynthetixBridgeToBase bridgeToBase;
        bytes memory messageData =
            abi.encodeWithSelector(bridgeToBase.finalizeFeePeriodClose.selector, snxBackedAmount, totalDebtShares);
        messenger().sendMessage(
            synthetixBridgeToBase(),
            messageData,
            uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.CloseFeePeriod))
        );
        emit FeePeriodClosed(snxBackedAmount, totalDebtShares);
    }
    function finalizeWithdrawal(address to, uint256 amount) external onlyCounterpart {
        synthetixERC20().transferFrom(synthetixBridgeEscrow(), to, amount);
        emit iOVM_L1TokenGateway.WithdrawalFinalized(to, amount);
    }
    function notifyRewardAmount(uint256 amount) external {
        require(msg.sender == address(rewardsDistribution()), "Caller is not RewardsDistribution contract");
        synthetixERC20().transfer(synthetixBridgeEscrow(), amount);
        _depositReward(msg.sender, amount);
    }
    function depositAndMigrateEscrow(uint256 depositAmount, uint256[][] memory entryIDs)
        public
        requireInitiationActive
        requireZeroDebt
    {
        if (entryIDs.length > 0) {
            _migrateEscrow(entryIDs);
        }
        if (depositAmount > 0) {
            _initiateDeposit(msg.sender, depositAmount);
        }
    }
    function _depositReward(address _from, uint256 _amount) internal {
        ISynthetixBridgeToBase bridgeToBase;
        bytes memory messageData = abi.encodeWithSelector(bridgeToBase.finalizeRewardDeposit.selector, _from, _amount);
        messenger().sendMessage(
            synthetixBridgeToBase(),
            messageData,
            uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Reward))
        );
        emit RewardDepositInitiated(_from, _amount);
    }
    function _initiateDeposit(address _to, uint256 _depositAmount) private {
        synthetixERC20().transferFrom(msg.sender, synthetixBridgeEscrow(), _depositAmount);
        iOVM_L2DepositedToken bridgeToBase;
        bytes memory messageData = abi.encodeWithSelector(bridgeToBase.finalizeDeposit.selector, _to, _depositAmount);
        messenger().sendMessage(
            synthetixBridgeToBase(),
            messageData,
            uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Deposit))
        );
        emit iOVM_L1TokenGateway.DepositInitiated(msg.sender, _to, _depositAmount);
    }
    function _migrateEscrow(uint256[][] memory _entryIDs) private {
        for (uint256 i = 0; i < _entryIDs.length; i++) {
            require(_entryIDs[i].length <= MAX_ENTRIES_MIGRATED_PER_MESSAGE, "Exceeds max entries per migration");
            uint256 escrowedAccountBalance;
            VestingEntries.VestingEntry[] memory vestingEntries;
            (escrowedAccountBalance, vestingEntries) = rewardEscrowV2().burnForMigration(msg.sender, _entryIDs[i]);
            if (escrowedAccountBalance > 0) {
                synthetixERC20().transfer(synthetixBridgeEscrow(), escrowedAccountBalance);
                ISynthetixBridgeToBase bridgeToBase;
                bytes memory messageData =
                    abi.encodeWithSelector(
                        bridgeToBase.finalizeEscrowMigration.selector,
                        msg.sender,
                        escrowedAccountBalance,
                        vestingEntries
                    );
                messenger().sendMessage(
                    synthetixBridgeToBase(),
                    messageData,
                    uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Escrow))
                );
                emit ExportedVestingEntries(msg.sender, escrowedAccountBalance, vestingEntries);
            }
        }
    }
    event ExportedVestingEntries(
        address indexed account,
        uint256 escrowedAccountBalance,
        VestingEntries.VestingEntry[] vestingEntries
    );
    event RewardDepositInitiated(address indexed account, uint256 amount);
    event FeePeriodClosed(uint snxBackedDebt, uint totalDebtShares);
}