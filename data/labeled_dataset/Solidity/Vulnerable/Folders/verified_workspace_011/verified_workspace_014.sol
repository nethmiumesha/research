pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPoolManager.sol";
import "./IOracle.sol";
import "./IPerpetualManager.sol";
import "./ISanToken.sol";
struct MintBurnData {
    uint64[] xFeeMint;
    uint64[] yFeeMint;
    uint64[] xFeeBurn;
    uint64[] yFeeBurn;
    uint64 targetHAHedge;
    uint64 bonusMalusMint;
    uint64 bonusMalusBurn;
    uint256 capOnStableMinted;
}
struct SLPData {
    uint256 lastBlockUpdated;
    uint256 lockedInterests;
    uint256 maxInterestsDistributed;
    uint256 feesAside;
    uint64 slippageFee;
    uint64 feesForSLPs;
    uint64 slippage;
    uint64 interestsForSLPs;
}
interface IStableMasterFunctions {
    function deploy(
        address[] memory _governorList,
        address _guardian,
        address _agToken
    ) external;
    function accumulateInterest(uint256 gain) external;
    function signalLoss(uint256 loss) external;
    function getStocksUsers() external view returns (uint256 maxCAmountInStable);
    function convertToSLP(uint256 amount, address user) external;
    function getCollateralRatio() external returns (uint256);
    function setFeeKeeper(
        uint64 feeMint,
        uint64 feeBurn,
        uint64 _slippage,
        uint64 _slippageFee
    ) external;
    function updateStocksUsers(uint256 amount, address poolManager) external;
    function setCore(address newCore) external;
    function addGovernor(address _governor) external;
    function removeGovernor(address _governor) external;
    function setGuardian(address newGuardian, address oldGuardian) external;
    function revokeGuardian(address oldGuardian) external;
    function setCapOnStableAndMaxInterests(
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed,
        IPoolManager poolManager
    ) external;
    function setIncentivesForSLPs(
        uint64 _feesForSLPs,
        uint64 _interestsForSLPs,
        IPoolManager poolManager
    ) external;
    function setUserFees(
        IPoolManager poolManager,
        uint64[] memory _xFee,
        uint64[] memory _yFee,
        uint8 _mint
    ) external;
    function setTargetHAHedge(uint64 _targetHAHedge) external;
    function pause(bytes32 agent, IPoolManager poolManager) external;
    function unpause(bytes32 agent, IPoolManager poolManager) external;
}
interface IStableMaster is IStableMasterFunctions {
    function agToken() external view returns (address);
    function collateralMap(IPoolManager poolManager)
        external
        view
        returns (
            IERC20 token,
            ISanToken sanToken,
            IPerpetualManager perpetualManager,
            IOracle oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );
}