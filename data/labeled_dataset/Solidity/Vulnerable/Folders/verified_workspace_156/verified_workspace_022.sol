pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBasePool } from "../vault/IBasePool.sol";
struct AmplificationState {
    uint64 startValue;
    uint64 endValue;
    uint32 startTime;
    uint32 endTime;
}
struct StablePoolImmutableData {
    IERC20[] tokens;
    uint256[] decimalScalingFactors;
    uint256 amplificationParameterPrecision;
}
struct StablePoolDynamicData {
    uint256[] balancesLiveScaled18;
    uint256[] tokenRates;
    uint256 staticSwapFeePercentage;
    uint256 totalSupply;
    uint256 bptRate;
    uint256 amplificationParameter;
    uint256 startValue;
    uint256 endValue;
    uint32 startTime;
    uint32 endTime;
    bool isAmpUpdating;
    bool isPoolInitialized;
    bool isPoolPaused;
    bool isPoolInRecoveryMode;
}
interface IStablePool is IBasePool {
    function startAmplificationParameterUpdate(uint256 rawEndValue, uint256 endTime) external;
    function stopAmplificationParameterUpdate() external;
    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision);
    function getAmplificationState()
        external
        view
        returns (AmplificationState memory amplificationState, uint256 precision);
    function getStablePoolDynamicData() external view returns (StablePoolDynamicData memory data);
    function getStablePoolImmutableData() external view returns (StablePoolImmutableData memory data);
}