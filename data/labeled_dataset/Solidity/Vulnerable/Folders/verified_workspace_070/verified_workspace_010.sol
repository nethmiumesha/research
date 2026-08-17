pragma solidity ^0.8.0;
import "./interfaces/WETH9.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SpokePool.sol";
import "./SpokePoolInterface.sol";
import "./PolygonTokenBridger.sol";
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}
contract Polygon_SpokePool is IFxMessageProcessor, SpokePool {
    using SafeERC20 for PolygonIERC20;
    address public fxChild;
    PolygonTokenBridger public polygonTokenBridger;
    bool private callValidated = false;
    event PolygonTokensBridged(address indexed token, address indexed receiver, uint256 amount);
    event SetFxChild(address indexed newFxChild);
    event SetPolygonTokenBridger(address indexed polygonTokenBridger);
    modifier validateInternalCalls() {
        callValidated = true;
        _;
        callValidated = false;
    }
    constructor(
        PolygonTokenBridger _polygonTokenBridger,
        address _crossDomainAdmin,
        address _hubPool,
        address _wmaticAddress,
        address _fxChild,
        address timerAddress
    ) SpokePool(_crossDomainAdmin, _hubPool, _wmaticAddress, timerAddress) {
        polygonTokenBridger = _polygonTokenBridger;
        fxChild = _fxChild;
    }
    function setFxChild(address newFxChild) public onlyAdmin nonReentrant {
        fxChild = newFxChild;
        emit SetFxChild(fxChild);
    }
    function setPolygonTokenBridger(address payable newPolygonTokenBridger) public onlyAdmin nonReentrant {
        polygonTokenBridger = PolygonTokenBridger(newPolygonTokenBridger);
        emit SetPolygonTokenBridger(address(polygonTokenBridger));
    }
    function processMessageFromRoot(
        uint256,
        address rootMessageSender,
        bytes calldata data
    ) public validateInternalCalls {
        require(msg.sender == fxChild, "Not from fxChild");
        require(rootMessageSender == crossDomainAdmin, "Not from mainnet admin");
        (bool success, ) = address(this).delegatecall(data);
        require(success, "delegatecall failed");
    }
    function _bridgeTokensToHubPool(RelayerRefundLeaf memory relayerRefundLeaf) internal override {
        PolygonIERC20(relayerRefundLeaf.l2TokenAddress).safeIncreaseAllowance(
            address(polygonTokenBridger),
            relayerRefundLeaf.amountToReturn
        );
        polygonTokenBridger.send(
            PolygonIERC20(relayerRefundLeaf.l2TokenAddress),
            relayerRefundLeaf.amountToReturn,
            address(weth) == relayerRefundLeaf.l2TokenAddress
        );
        emit PolygonTokensBridged(relayerRefundLeaf.l2TokenAddress, address(this), relayerRefundLeaf.amountToReturn);
    }
    function _requireAdminSender() internal view override {
        require(callValidated, "Must call processMessageFromRoot");
    }
}