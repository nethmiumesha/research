pragma solidity ^0.8.0;
import "./interfaces/WETH9.sol";
import "@eth-optimism/contracts/libraries/bridge/CrossDomainEnabled.sol";
import "@eth-optimism/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import "@eth-optimism/contracts/L2/messaging/IL2ERC20Bridge.sol";
import "./SpokePool.sol";
import "./SpokePoolInterface.sol";
contract Optimism_SpokePool is CrossDomainEnabled, SpokePool {
    uint32 public l1Gas = 5_000_000;
    address public l2Eth = address(Lib_PredeployAddresses.OVM_ETH);
    event OptimismTokensBridged(address indexed l2Token, address target, uint256 numberOfTokensBridged, uint256 l1Gas);
    event SetL1Gas(uint32 indexed newL1Gas);
    constructor(
        address _crossDomainAdmin,
        address _hubPool,
        address timerAddress
    )
        CrossDomainEnabled(Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER)
        SpokePool(_crossDomainAdmin, _hubPool, 0x4200000000000000000000000000000000000006, timerAddress)
    {}
    function setL1GasLimit(uint32 newl1Gas) public onlyAdmin {
        l1Gas = newl1Gas;
        emit SetL1Gas(newl1Gas);
    }
    function executeSlowRelayRoot(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 totalRelayAmount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) public override(SpokePool) nonReentrant {
        if (destinationToken == address(weth)) _depositEthToWeth();
        _executeSlowRelayRoot(
            depositor,
            recipient,
            destinationToken,
            totalRelayAmount,
            originChainId,
            realizedLpFeePct,
            relayerFeePct,
            depositId,
            rootBundleId,
            proof
        );
    }
    function executeRelayerRefundRoot(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) public override(SpokePool) nonReentrant {
        if (relayerRefundLeaf.l2TokenAddress == address(weth)) _depositEthToWeth();
        _executeRelayerRefundRoot(rootBundleId, relayerRefundLeaf, proof);
    }
    function _depositEthToWeth() internal {
        if (address(this).balance > 0) weth.deposit{ value: address(this).balance }();
    }
    function _bridgeTokensToHubPool(RelayerRefundLeaf memory relayerRefundLeaf) internal override {
        if (relayerRefundLeaf.l2TokenAddress == address(weth)) {
            WETH9(relayerRefundLeaf.l2TokenAddress).withdraw(relayerRefundLeaf.amountToReturn);
            relayerRefundLeaf.l2TokenAddress = l2Eth;
        }
        IL2ERC20Bridge(Lib_PredeployAddresses.L2_STANDARD_BRIDGE).withdrawTo(
            relayerRefundLeaf.l2TokenAddress,
            hubPool,
            relayerRefundLeaf.amountToReturn,
            l1Gas,
            ""
        );
        emit OptimismTokensBridged(relayerRefundLeaf.l2TokenAddress, hubPool, relayerRefundLeaf.amountToReturn, l1Gas);
    }
    function _requireAdminSender() internal override onlyFromCrossDomainAccount(crossDomainAdmin) {}
}