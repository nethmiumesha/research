pragma solidity ^0.8.0;
interface SpokePoolInterface {
    struct RelayerRefundLeaf {
        uint256 amountToReturn;
        uint256 chainId;
        uint256[] refundAmounts;
        uint32 leafId;
        address l2TokenAddress;
        address[] refundAddresses;
    }
    struct RelayData {
        address depositor;
        address recipient;
        address destinationToken;
        uint256 amount;
        uint256 originChainId;
        uint64 realizedLpFeePct;
        uint64 relayerFeePct;
        uint32 depositId;
    }
    function setCrossDomainAdmin(address newCrossDomainAdmin) external;
    function setHubPool(address newHubPool) external;
    function setEnableRoute(
        address originToken,
        uint256 destinationChainId,
        bool enable
    ) external;
    function setDepositQuoteTimeBuffer(uint32 buffer) external;
    function relayRootBundle(bytes32 relayerRefundRoot, bytes32 slowRelayRoot) external;
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
    function speedUpDeposit(
        address depositor,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) external;
    function fillRelay(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId
    ) external;
    function fillRelayWithUpdatedFee(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) external;
    function executeSlowRelayRoot(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) external;
    function executeRelayerRefundRoot(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) external;
    function chainId() external view returns (uint256);
}