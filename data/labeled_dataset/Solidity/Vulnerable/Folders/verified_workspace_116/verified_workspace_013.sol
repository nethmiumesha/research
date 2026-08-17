pragma solidity ^0.8.33;
interface IDSF {
    function totalDeposited() external view returns (uint256);
    function deposited(address account) external view returns (uint256);
    function totalHoldings() external view returns (uint256);
    function calcManagementFee(uint256 amount) external view returns (uint256);
    function defaultDepositPid() external view returns (uint256);
    function poolInfo(uint256 pid)
        external
        view
        returns (address strategy, uint256 startTime, uint256 lpShares);
}