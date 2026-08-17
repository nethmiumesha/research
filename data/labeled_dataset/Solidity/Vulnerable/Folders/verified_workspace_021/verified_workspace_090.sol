pragma solidity ^0.5.16;
import "./BaseSynthetix.sol";
import "./interfaces/IRewardEscrow.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/ISupplySchedule.sol";
contract Synthetix is BaseSynthetix {
    bytes32 public constant CONTRACT_NAME = "Synthetix";
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_SUPPLYSCHEDULE = "SupplySchedule";
    constructor(
        address payable _proxy,
        TokenState _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    ) public BaseSynthetix(_proxy, _tokenState, _owner, _totalSupply, _resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseSynthetix.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_REWARD_ESCROW;
        newAddresses[1] = CONTRACT_REWARDESCROW_V2;
        newAddresses[2] = CONTRACT_SUPPLYSCHEDULE;
        return combineArrays(existingAddresses, newAddresses);
    }
    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARD_ESCROW));
    }
    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }
    function supplySchedule() internal view returns (ISupplySchedule) {
        return ISupplySchedule(requireAndGetAddress(CONTRACT_SUPPLYSCHEDULE));
    }
    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    )
        external
        exchangeActive(sourceCurrencyKey, destinationCurrencyKey)
        optionalProxy
        returns (uint amountReceived, IVirtualSynth vSynth)
    {
        return
            exchanger().exchange(
                messageSender,
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                true,
                messageSender,
                trackingCode
            );
    }
    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint amountReceived) {
        (amountReceived, ) = exchanger().exchange(
            messageSender,
            messageSender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            tx.origin,
            false,
            rewardAddress,
            trackingCode
        );
    }
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint minAmount
    ) external exchangeActive(sourceCurrencyKey, destinationCurrencyKey) optionalProxy returns (uint amountReceived) {
        return
            exchanger().exchangeAtomically(
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                trackingCode,
                minAmount
            );
    }
    function settle(bytes32 currencyKey)
        external
        optionalProxy
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntriesSettled
        )
    {
        return exchanger().settle(messageSender, currencyKey);
    }
    function mint() external issuanceActive returns (bool) {
        require(address(rewardsDistribution()) != address(0), "RewardsDistribution not set");
        ISupplySchedule _supplySchedule = supplySchedule();
        IRewardsDistribution _rewardsDistribution = rewardsDistribution();
        uint supplyToMint = _supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");
        emitTransfer(address(0), address(this), supplyToMint);
        uint minterReward = _supplySchedule.recordMintEvent(supplyToMint);
        uint amountToDistribute = supplyToMint.sub(minterReward);
        tokenState.setBalanceOf(
            address(_rewardsDistribution),
            tokenState.balanceOf(address(_rewardsDistribution)).add(amountToDistribute)
        );
        emitTransfer(address(this), address(_rewardsDistribution), amountToDistribute);
        _rewardsDistribution.distributeRewards(amountToDistribute);
        tokenState.setBalanceOf(msg.sender, tokenState.balanceOf(msg.sender).add(minterReward));
        emitTransfer(address(this), msg.sender, minterReward);
        totalSupply = totalSupply.add(supplyToMint);
        return true;
    }
    function migrateEscrowBalanceToRewardEscrowV2() external onlyOwner {
        uint rewardEscrowBalance = tokenState.balanceOf(address(rewardEscrow()));
        _internalTransfer(address(rewardEscrow()), address(rewardEscrowV2()), rewardEscrowBalance);
    }
    event AtomicSynthExchange(
        address indexed account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    );
    bytes32 internal constant ATOMIC_SYNTH_EXCHANGE_SIG =
        keccak256("AtomicSynthExchange(address,bytes32,uint256,bytes32,uint256,address)");
    function emitAtomicSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external onlyExchanger {
        proxy._emit(
            abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress),
            2,
            ATOMIC_SYNTH_EXCHANGE_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}