pragma solidity >=0.4.24;
import "./IERC20.sol";
interface ISynthRedeemer {
    function redemptions(address synthProxy) external view returns (uint redeemRate);
    function balanceOf(IERC20 synthProxy, address account) external view returns (uint balanceOfInsUSD);
    function totalSupply(IERC20 synthProxy) external view returns (uint totalSupplyInsUSD);
    function redeem(IERC20 synthProxy) external;
    function redeemAll(IERC20[] calldata synthProxies) external;
    function redeemPartial(IERC20 synthProxy, uint amountOfSynth) external;
    function deprecate(IERC20 synthProxy, uint rateToRedeem) external;
}