pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
interface IQDistributor {
    struct UserInfo {
        uint accruedQubit;
        uint boostedSupply;
        uint boostedBorrow;
        uint accPerShareSupply;
        uint accPerShareBorrow;
    }
    struct DistributionInfo {
        uint supplyRate;
        uint borrowRate;
        uint totalBoostedSupply;
        uint totalBoostedBorrow;
        uint accPerShareSupply;
        uint accPerShareBorrow;
        uint accruedAt;
    }
    function accruedQubit(address market, address user) external view returns (uint);
    function qubitRatesOf(address market) external view returns (uint supplyRate, uint borrowRate);
    function totalBoosted(address market) external view returns (uint boostedSupply, uint boostedBorrow);
    function boostedBalanceOf(address market, address account)
        external
        view
        returns (uint boostedSupply, uint boostedBorrow);
    function notifySupplyUpdated(address market, address user) external;
    function notifyBorrowUpdated(address market, address user) external;
    function notifyTransferred(
        address qToken,
        address sender,
        address receiver
    ) external;
    function claimQubit(address user) external;
    function kick(address user) external;
}