pragma solidity ^0.8.34;
import "../utils/Constants.sol";
import "./CurveConvexStrat_crvUSD_USDT.sol";
contract ConvexStratedgy_CRVUSD_USDT is CurveConvexStrat_crvUSD_USDT {
    constructor(Config memory config)
        CurveConvexStrat_crvUSD_USDT(
            config,
            Constants.CRV_CRVUSD_USDT_ADDRESS,
            Constants.CRV_CRVUSD_USDT_LP_ADDRESS,
            Constants.CVX_CRVUSD_USDT_REWARDS_ADDRESS,
            Constants.CVX_CRVUSD_USDT_PID,
            Constants.USDT_ADDRESS,
            address(0),
            address(0)
        )
    {}
}