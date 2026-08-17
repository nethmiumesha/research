pragma solidity >=0.8.29 <0.9.0;
interface ICustomStrategyHelper {
    function getWithdrawCalldata(
        address strategy,
        uint256 amount
    ) external view returns (address[] memory targets, bytes[] memory calldatas);
}