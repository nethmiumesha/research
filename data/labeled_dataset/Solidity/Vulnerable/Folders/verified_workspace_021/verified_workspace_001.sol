pragma solidity ^0.5.16;
import "../TradingRewards.sol";
import "../interfaces/IExchanger.sol";
contract FakeTradingRewards is TradingRewards {
    IERC20 public _mockSynthetixToken;
    constructor(
        address owner,
        address periodController,
        address resolver,
        address mockSynthetixToken
    ) public TradingRewards(owner, periodController, resolver) {
        _mockSynthetixToken = IERC20(mockSynthetixToken);
    }
    function synthetix() internal view returns (IERC20) {
        return IERC20(_mockSynthetixToken);
    }
    function exchanger() internal view returns (IExchanger) {
        return IExchanger(msg.sender);
    }
}