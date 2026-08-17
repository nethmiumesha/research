pragma solidity 0.5.8;
import "../interfaces/IDataStore.sol";
import "../interfaces/IModuleRegistry.sol";
import "../interfaces/IPolymathRegistry.sol";
import "../interfaces/ISecurityTokenRegistry.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
contract SecurityTokenStorage {
    uint8 internal constant PERMISSION_KEY = 1;
    uint8 internal constant TRANSFER_KEY = 2;
    uint8 internal constant MINT_KEY = 3;
    uint8 internal constant CHECKPOINT_KEY = 4;
    uint8 internal constant BURN_KEY = 5;
    uint8 internal constant DATA_KEY = 6;
    uint8 internal constant WALLET_KEY = 7;
    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731;
    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6;
    bytes32 internal constant LOCKED = "LOCKED";
    bytes32 internal constant UNLOCKED = "UNLOCKED";
    struct Document {
        bytes32 docHash;
        uint256 lastModified;
        string uri;
    }
    struct SemanticVersion {
        uint8 major;
        uint8 minor;
        uint8 patch;
    }
    struct ModuleData {
        bytes32 name;
        address module;
        address moduleFactory;
        bool isArchived;
        uint8[] moduleTypes;
        uint256[] moduleIndexes;
        uint256 nameIndex;
        bytes32 label;
    }
    struct Checkpoint {
        uint256 checkpointId;
        uint256 value;
    }
    address internal _owner;
    address public tokenFactory;
    bool public initialized;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public controller;
    IPolymathRegistry public polymathRegistry;
    IModuleRegistry public moduleRegistry;
    ISecurityTokenRegistry public securityTokenRegistry;
    IERC20 public polyToken;
    address public getterDelegate;
    IDataStore public dataStore;
    uint256 public granularity;
    uint256 public currentCheckpointId;
    string public tokenDetails;
    bool public controllerDisabled = false;
    bool public transfersFrozen;
    uint256 public holderCount;
    bool internal issuance = true;
    bytes32[] _docNames;
    uint256[] checkpointTimes;
    SemanticVersion securityTokenVersion;
    mapping(uint8 => address[]) modules;
    mapping(address => ModuleData) modulesToData;
    mapping(bytes32 => address[]) names;
    mapping (uint256 => uint256) checkpointTotalSupply;
    mapping(address => Checkpoint[]) checkpointBalances;
    mapping(bytes32 => Document) internal _documents;
    mapping(bytes32 => uint256) internal _docIndexes;
    mapping (address => mapping (bytes32 => mapping (address => bool))) partitionApprovals;
}