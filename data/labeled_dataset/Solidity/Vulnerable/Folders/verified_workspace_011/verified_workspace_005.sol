pragma solidity ^0.8.7;
import "./StableMasterEvents.sol";
contract StableMasterStorage is StableMasterEvents, FunctionUtils {
    struct Collateral {
        IERC20 token;
        ISanToken sanToken;
        IPerpetualManager perpetualManager;
        IOracle oracle;
        uint256 stocksUsers;
        uint256 sanRate;
        uint256 collatBase;
        SLPData slpData;
        MintBurnData feeData;
    }
    mapping(IPoolManager => Collateral) public collateralMap;
    IAgToken public agToken;
    mapping(address => IPoolManager) internal _contractMap;
    IPoolManager[] internal _managerList;
    ICore internal _core;
}