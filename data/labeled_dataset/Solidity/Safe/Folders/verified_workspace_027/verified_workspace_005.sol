pragma solidity 0.5.8;
import "./SecurityTokenProxy.sol";
import "../proxy/OwnedUpgradeabilityProxy.sol";
import "../interfaces/ISTFactory.sol";
import "../interfaces/ISecurityToken.sol";
import "../interfaces/IPolymathRegistry.sol";
import "../interfaces/IOwnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/IModuleRegistry.sol";
import "../interfaces/IPolymathRegistry.sol";
import "../datastore/DataStoreFactory.sol";
contract STFactory is ISTFactory, Ownable {
    address public transferManagerFactory;
    DataStoreFactory public dataStoreFactory;
    IPolymathRegistry public polymathRegistry;
    mapping (address => uint256) tokenUpgrade;
    struct LogicContract {
        string version;
        address logicContract;
        bytes initializationData;
        bytes upgradeData;
    }
    mapping (uint256 => LogicContract) logicContracts;
    uint256 public latestUpgrade;
    event LogicContractSet(string _version, uint256 _upgrade, address _logicContract, bytes _initializationData, bytes _upgradeData);
    event TokenUpgraded(
        address indexed _securityToken,
        uint256 indexed _version
    );
    event DefaultTransferManagerUpdated(address indexed _oldTransferManagerFactory, address indexed _newTransferManagerFactory);
    event DefaultDataStoreUpdated(address indexed _oldDataStoreFactory, address indexed _newDataStoreFactory);
    constructor(
        address _polymathRegistry,
        address _transferManagerFactory,
        address _dataStoreFactory,
        string memory _version,
        address _logicContract,
        bytes memory _initializationData
    )
        public
    {
        require(_logicContract != address(0), "Invalid Address");
        require(_transferManagerFactory != address(0), "Invalid Address");
        require(_dataStoreFactory != address(0), "Invalid Address");
        require(_polymathRegistry != address(0), "Invalid Address");
        require(_initializationData.length > 4, "Invalid Initialization");
        require(bytes(_version).length != 0, "Empty version");
        transferManagerFactory = _transferManagerFactory;
        dataStoreFactory = DataStoreFactory(_dataStoreFactory);
        polymathRegistry = IPolymathRegistry(_polymathRegistry);
        latestUpgrade = 1;
        logicContracts[latestUpgrade].logicContract = _logicContract;
        logicContracts[latestUpgrade].initializationData = _initializationData;
        logicContracts[latestUpgrade].version = _version;
    }
    function deployToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        string calldata _tokenDetails,
        address _issuer,
        bool _divisible,
        address _treasuryWallet
    )
        external
        returns(address)
    {
        address securityToken = _deploy(
            _name,
            _symbol,
            _decimals,
            _tokenDetails,
            _divisible
        );
        if (address(dataStoreFactory) != address(0)) {
            ISecurityToken(securityToken).changeDataStore(dataStoreFactory.generateDataStore(securityToken));
        }
        ISecurityToken(securityToken).changeTreasuryWallet(_treasuryWallet);
        if (transferManagerFactory != address(0)) {
            ISecurityToken(securityToken).addModule(transferManagerFactory, "", 0, 0, false);
        }
        IOwnable(securityToken).transferOwnership(_issuer);
        return securityToken;
    }
    function _deploy(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _tokenDetails,
        bool _divisible
    ) internal returns(address) {
        SecurityTokenProxy proxy = new SecurityTokenProxy(
            _name,
            _symbol,
            _decimals,
            _divisible ? 1 : uint256(10) ** _decimals,
            _tokenDetails,
            address(polymathRegistry)
        );
        proxy.upgradeTo(logicContracts[latestUpgrade].version, logicContracts[latestUpgrade].logicContract);
        (bool success, ) = address(proxy).call(logicContracts[latestUpgrade].initializationData);
        require(success, "Unsuccessful initialization");
        tokenUpgrade[address(proxy)] = latestUpgrade;
        return address(proxy);
    }
    function setLogicContract(string calldata _version, address _logicContract, bytes calldata _initializationData, bytes calldata _upgradeData) external onlyOwner {
        require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[latestUpgrade].version)), "Same version");
        require(_logicContract != logicContracts[latestUpgrade].logicContract, "Same logic contract");
        require(_logicContract != address(0), "Invalid address");
        require(_initializationData.length > 4, "Invalid Initialization");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        latestUpgrade++;
        _modifyLogicContract(latestUpgrade, _version, _logicContract, _initializationData, _upgradeData);
    }
    function updateLogicContract(uint256 _upgrade, string calldata _version, address _logicContract, bytes calldata _initializationData, bytes calldata _upgradeData) external onlyOwner {
        require(_upgrade <= latestUpgrade, "Invalid upgrade");
        require(_upgrade > 0, "Invalid upgrade");
        if (_upgrade > 1) {
          require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[_upgrade - 1].version)), "Same version");
          require(_logicContract != logicContracts[_upgrade - 1].logicContract, "Same logic contract");
        }
        require(_logicContract != address(0), "Invalid address");
        require(_initializationData.length > 4, "Invalid Initialization");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        _modifyLogicContract(_upgrade, _version, _logicContract, _initializationData, _upgradeData);
    }
    function _modifyLogicContract(uint256 _upgrade, string memory _version, address _logicContract, bytes memory _initializationData, bytes memory _upgradeData) internal {
        logicContracts[_upgrade].version = _version;
        logicContracts[_upgrade].logicContract = _logicContract;
        logicContracts[_upgrade].upgradeData = _upgradeData;
        logicContracts[_upgrade].initializationData = _initializationData;
        emit LogicContractSet(_version, _upgrade, _logicContract, _initializationData, _upgradeData);
    }
    function upgradeToken(uint8 _maxModuleType) external {
        require(tokenUpgrade[msg.sender] != 0, "Invalid token");
        uint256 newVersion = tokenUpgrade[msg.sender] + 1;
        require(newVersion <= latestUpgrade, "Incorrect version");
        OwnedUpgradeabilityProxy(address(uint160(msg.sender))).upgradeToAndCall(logicContracts[newVersion].version, logicContracts[newVersion].logicContract, logicContracts[newVersion].upgradeData);
        tokenUpgrade[msg.sender] = newVersion;
        IModuleRegistry moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        address moduleFactory;
        bool isArchived;
        for (uint8 i = 1; i < _maxModuleType; i++) {
            address[] memory modules = ISecurityToken(msg.sender).getModulesByType(i);
            for (uint256 j = 0; j < modules.length; j++) {
                (,, moduleFactory, isArchived,,) = ISecurityToken(msg.sender).getModule(modules[j]);
                if (!isArchived) {
                    require(moduleRegistry.isCompatibleModule(moduleFactory, msg.sender), "Incompatible Modules");
                }
            }
        }
        emit TokenUpgraded(msg.sender, newVersion);
    }
    function updateDefaultTransferManager(address _transferManagerFactory) external onlyOwner {
        emit DefaultTransferManagerUpdated(transferManagerFactory, _transferManagerFactory);
        transferManagerFactory = _transferManagerFactory;
    }
    function updateDefaultDataStore(address _dataStoreFactory) external onlyOwner {
        emit DefaultDataStoreUpdated(address(dataStoreFactory), address(_dataStoreFactory));
        dataStoreFactory = DataStoreFactory(_dataStoreFactory);
    }
}