pragma solidity ^0.6.12;
interface IQubitPresale {
    struct PresaleData {
        uint startTime;
        uint endTime;
        uint userLpAmount;
        uint totalLpAmount;
        bool claimedOf;
        uint refundLpAmount;
        uint qbtBnbLpAmount;
    }
    function lpPriceAtArchive() external view returns (uint);
    function qbtBnbLpAmount() external view returns (uint);
    function allocationOf(address _user) external view returns (uint);
    function refundOf(address _user) external view returns (uint);
    function accountListLength() external view returns (uint);
    function setQubitBnbLocker(address _qubitBnbLocker) external;
    function setPresaleAmountUSD(uint _limitAmount) external;
    function setPeriod(uint _start, uint _end) external;
    function setQbtAmount(uint _qbtAmount) external;
    function deposit(uint _amount) external;
    function archive() external returns (uint bunnyAmount, uint wbnbAmount);
    function distribute(uint distributeThreshold) external;
    function sweep(uint _lpAmount, uint _offerAmount) external;
}