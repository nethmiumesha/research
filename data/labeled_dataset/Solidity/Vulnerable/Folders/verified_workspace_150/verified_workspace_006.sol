pragma solidity >=0.8.0;
import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";
interface IRateLimits is IAccessControl {
    struct RateLimitData {
        uint256 maxAmount;
        uint256 slope;
        uint256 lastAmount;
        uint256 lastUpdated;
    }
    event RateLimitDataSet(
        bytes32 indexed key,
        uint256 maxAmount,
        uint256 slope,
        uint256 lastAmount,
        uint256 lastUpdated
    );
    event RateLimitDecreaseTriggered(
        bytes32 indexed key,
        uint256 amountToDecrease,
        uint256 oldRateLimit,
        uint256 newRateLimit
    );
    event RateLimitIncreaseTriggered(
        bytes32 indexed key,
        uint256 amountToIncrease,
        uint256 oldRateLimit,
        uint256 newRateLimit
    );
    function CONTROLLER() external view returns (bytes32);
    function setRateLimitData(
        bytes32 key,
        uint256 maxAmount,
        uint256 slope,
        uint256 lastAmount,
        uint256 lastUpdated
    ) external;
    function setRateLimitData(bytes32 key, uint256 maxAmount, uint256 slope) external;
    function setUnlimitedRateLimitData(bytes32 key) external;
    function getRateLimitData(bytes32 key) external view returns (RateLimitData memory);
    function getCurrentRateLimit(bytes32 key) external view returns (uint256);
    function triggerRateLimitDecrease(bytes32 key, uint256 amountToDecrease)
        external returns (uint256 newLimit);
    function triggerRateLimitIncrease(bytes32 key, uint256 amountToIncrease)
        external returns (uint256 newLimit);
}