pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
interface IQubitLocker {
    struct CheckPoint {
        uint totalWeightedBalance;
        uint slope;
        uint ts;
    }
    function totalBalance() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function expiryOf(address account) external view returns (uint);
    function availableOf(address account) external view returns (uint);
    function balanceExpiryOf(address account) external view returns (uint balance, uint expiry);
    function totalScore() external view returns (uint score, uint slope);
    function scoreOf(address account) external view returns (uint);
    function deposit(uint amount, uint unlockTime) external;
    function extendLock(uint expiryTime) external;
    function withdraw() external;
    function depositBehalf(
        address account,
        uint amount,
        uint unlockTime
    ) external;
    function withdrawBehalf(address account) external;
}