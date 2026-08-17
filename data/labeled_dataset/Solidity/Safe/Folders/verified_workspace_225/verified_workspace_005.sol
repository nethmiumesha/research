pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;
import "../../Lib/LibDerivative.sol";
import "../../Core.sol";
import "../../SyntheticAggregator.sol";
import "./MatchLogic.sol";
contract MatchPool is MatchLogic, LibDerivative {
    constructor (address _registry) public usingRegistry(_registry) {}
    function create(Order memory _buyOrder, Derivative memory _derivative) public nonReentrant {
        require(
            _buyOrder.makerTokenId == 0,
            "MATCH:NOT_CREATION"
        );
        require(IDerivativeLogic(_derivative.syntheticId).isPool(), "MATCH:NOT_POOL");
        validateSenderAddress(_buyOrder);
        validateExpiration(_buyOrder);
        bytes32 orderHash;
        orderHash = hashOrder(_buyOrder);
        validateCanceled(orderHash);
        validateSignature(orderHash, _buyOrder);
        uint256 margin = calculatePool(_buyOrder, _derivative);
        takeFees(orderHash, _buyOrder);
        IERC20 marginToken = IERC20(_derivative.token);
        if (margin != 0) {
            require(marginToken.allowance(_buyOrder.makerAddress, registry.getTokenSpender()) >= margin.mul(_buyOrder.takerTokenAmount), "MATCH:NOT_ENOUGH_ALLOWED_MARGIN");
            TokenSpender(registry.getTokenSpender()).claimTokens(marginToken, _buyOrder.makerAddress, address(this), margin.mul(_buyOrder.takerTokenAmount));
            require(marginToken.approve(registry.getTokenSpender(), margin.mul(_buyOrder.takerTokenAmount)), "MATCH:COULDNT_APPROVE_MARGIN_FOR_CORE");
        }
        Core(registry.getCore()).create(_derivative, _buyOrder.takerTokenAmount, [_buyOrder.makerAddress, address(0)]);
    }
    function calculatePool(Order memory _buyOrder, Derivative memory _derivative) private returns (uint256 margin) {
        bytes32 derivativeHash = getDerivativeHash(_derivative);
        uint256 longTokenId = derivativeHash.getLongTokenId();
        require(
            _buyOrder.takerTokenId == longTokenId,
            "MATCH:DERIVATIVE_NOT_MATCH"
        );
        (margin, ) = SyntheticAggregator(registry.getSyntheticAggregator()).getMargin(derivativeHash, _derivative);
        require(
            margin == 0 || _buyOrder.makerMarginAddress == _derivative.token
            , "MATCH:PROVIDED_MARGIN_CURRENCY_WRONG"
        );
        require(
            _buyOrder.makerMarginAmount >= _buyOrder.takerTokenAmount.mul(margin),
            "MATCH:PROVIDED_MARGIN_NOT_ENOUGH"
        );
    }
}