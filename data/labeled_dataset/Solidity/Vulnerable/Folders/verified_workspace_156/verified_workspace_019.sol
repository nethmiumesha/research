pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInfo } from "../vault/VaultTypes.sol";
interface IPoolInfo {
    function getTokens() external view returns (IERC20[] memory tokens);
    function getTokenInfo()
        external
        view
        returns (
            IERC20[] memory tokens,
            TokenInfo[] memory tokenInfo,
            uint256[] memory balancesRaw,
            uint256[] memory lastBalancesLiveScaled18
        );
    function getCurrentLiveBalances() external view returns (uint256[] memory balancesLiveScaled18);
    function getStaticSwapFeePercentage() external view returns (uint256 staticSwapFeePercentage);
    function getAggregateFeePercentages()
        external
        view
        returns (uint256 aggregateSwapFeePercentage, uint256 aggregateYieldFeePercentage);
}