pragma solidity ^0.8.11;
interface ILenderPool {
    struct Round {
        bool paidTrade;
        uint16 stableAPY;
        uint16 bonusAPY;
        uint48 startPeriod;
        uint48 endPeriod;
        uint amountLent;
    }
    struct LenderInfo {
        uint amountLent;
        uint roundCount;
    }
    function setMinimumDeposit(uint newMinimumDeposit) external;
    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        bool paidTrade
    ) external;
    function sendToTreasury(address tokenAddress, uint amount) external;
    function withdraw(
        address lender,
        uint roundId,
        uint amountOutMin
    ) external;
    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory);
    function getLatestRound(address lender) external view returns (uint);
    function getAmountLent(address lender) external view returns (uint);
    function getFinishedRounds(address lender)
        external
        view
        returns (uint[] memory);
    function stableRewardOf(address lender, uint roundId)
        external
        view
        returns (uint);
    function bonusRewardOf(address lender, uint roundId)
        external
        view
        returns (uint);
    event MinimumDepositUpdated(
        uint previousMinimumDeposit,
        uint newMinimumDeposit
    );
    event NewTreasuryAddress(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );
    event TenureUpdated(uint16 oldTenure, uint16 newTenure);
    event StableAPYUpdated(uint previousStableAPY, uint newStableAPY);
    event Deposit(address indexed owner, uint indexed roundId, uint amount);
    event Withdraw(address indexed owner, uint indexed roundId, uint amount);
    event ClaimStable(
        address indexed lender,
        uint indexed roundId,
        uint amount
    );
    event ClaimTrade(address indexed lender, uint indexed roundId, uint amount);
    event Swapped(uint amountStable, uint amountTrade);
}