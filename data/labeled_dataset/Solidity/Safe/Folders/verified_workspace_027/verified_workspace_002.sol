pragma solidity 0.5.8;
import "../proxy/Proxy.sol";
import "../interfaces/IModule.sol";
import "./SecurityTokenStorage.sol";
import "../libraries/TokenLib.sol";
import "../libraries/StatusCodes.sol";
import "../interfaces/IDataStore.sol";
import "../interfaces/IUpgradableTokenFactory.sol";
import "../interfaces/IModuleFactory.sol";
import "../interfaces/token/IERC1410.sol";
import "../interfaces/token/IERC1594.sol";
import "../interfaces/token/IERC1643.sol";
import "../interfaces/token/IERC1644.sol";
import "../interfaces/ITransferManager.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
contract SecurityToken is ERC20, ReentrancyGuard, SecurityTokenStorage, IERC1594, IERC1643, IERC1644, IERC1410, Proxy {
    using SafeMath for uint256;
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );
    event ModuleUpgraded(uint8[] _types, address _module);
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    event UpdateTokenName(string _oldName, string _newName);
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    event FreezeIssuance();
    event FreezeTransfers(bool _status);
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    event SetController(address indexed _oldController, address indexed _newController);
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);
    event ModuleArchived(uint8[] _types, address _module);
    event ModuleUnarchived(uint8[] _types, address _module);
    event ModuleRemoved(uint8[] _types, address _module);
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget);
    constructor() public {
        initialized = true;
    }
    function initialize(address _getterDelegate) public {
        require(!initialized, "Already initialized");
        getterDelegate = _getterDelegate;
        securityTokenVersion = SemanticVersion(3, 0, 0);
        updateFromRegistry();
        tokenFactory = msg.sender;
        initialized = true;
    }
    function isModule(address _module, uint8 _type) public view returns(bool) {
        if (modulesToData[_module].module != _module || modulesToData[_module].isArchived)
            return false;
        for (uint256 i = 0; i < modulesToData[_module].moduleTypes.length; i++) {
            if (modulesToData[_module].moduleTypes[i] == _type) {
                return true;
            }
        }
        return false;
    }
    function _onlyModuleOrOwner(uint8 _type) internal view {
        if (msg.sender != owner())
            require(isModule(msg.sender, _type));
    }
    function _isValidPartition(bytes32 _partition) internal pure {
        require(_partition == UNLOCKED, "Invalid partition");
    }
    function _isValidOperator(address _from, address _operator, bytes32 _partition) internal view {
        _isAuthorised(
            allowance(_from, _operator) == uint(-1) || partitionApprovals[_from][_partition][_operator]
        );
    }
    function _zeroAddressCheck(address _entity) internal pure {
        require(_entity != address(0), "Invalid address");
    }
    function _isValidTransfer(bool _isTransfer) internal pure {
        require(_isTransfer, "Transfer Invalid");
    }
    function _isValidRedeem(bool _isRedeem) internal pure {
        require(_isRedeem, "Invalid redeem");
    }
    function _isSignedByOwner(bool _signed) internal pure {
        require(_signed, "Owner did not sign");
    }
    function _isIssuanceAllowed() internal view {
        require(issuance, "Issuance frozen");
    }
    function _onlyController() internal view {
        _isAuthorised(msg.sender == controller && isControllable());
    }
    function _isAuthorised(bool _authorised) internal pure {
        require(_authorised, "Not Authorised");
    }
    function _onlyOwner() internal view {
        require(isOwner());
    }
    function _onlyModule(uint8 _type) internal view {
        require(isModule(msg.sender, _type));
    }
    modifier checkGranularity(uint256 _value) {
        require(_value % granularity == 0, "Invalid granularity");
        _;
    }
    function addModuleWithLabel(
        address _moduleFactory,
        bytes memory _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    )
        public
        nonReentrant
    {
        _onlyOwner();
        moduleRegistry.useModule(_moduleFactory, false);
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        uint8[] memory moduleTypes = moduleFactory.getTypes();
        uint256 moduleCost = moduleFactory.setupCostInPoly();
        require(moduleCost <= _maxCost, "Invalid cost");
        polyToken.approve(_moduleFactory, moduleCost);
        address module = moduleFactory.deploy(_data);
        require(modulesToData[module].module == address(0), "Module exists");
        polyToken.approve(module, _budget);
        _addModuleData(moduleTypes, _moduleFactory, module, moduleCost, _budget, _label, _archived);
    }
    function _addModuleData(
        uint8[] memory _moduleTypes,
        address _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) internal {
        bytes32 moduleName = IModuleFactory(_moduleFactory).name();
        uint256[] memory moduleIndexes = new uint256[](_moduleTypes.length);
        uint256 i;
        for (i = 0; i < _moduleTypes.length; i++) {
            moduleIndexes[i] = modules[_moduleTypes[i]].length;
            modules[_moduleTypes[i]].push(_module);
        }
        modulesToData[_module] = ModuleData(
            moduleName,
            _module,
            _moduleFactory,
            _archived,
            _moduleTypes,
            moduleIndexes,
            names[moduleName].length,
            _label
        );
        names[moduleName].push(_module);
        emit ModuleAdded(_moduleTypes, moduleName, _moduleFactory, _module, _moduleCost, _budget, _label, _archived);
    }
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external {
        addModuleWithLabel(_moduleFactory, _data, _maxCost, _budget, "", _archived);
    }
    function archiveModule(address _module) external {
        _onlyOwner();
        TokenLib.archiveModule(modulesToData[_module]);
    }
    function upgradeModule(address _module) external {
        _onlyOwner();
        TokenLib.upgradeModule(moduleRegistry, modulesToData[_module]);
    }
    function upgradeToken() external {
        _onlyOwner();
        IUpgradableTokenFactory(tokenFactory).upgradeToken(10);
        emit TokenUpgraded(securityTokenVersion.major, securityTokenVersion.minor, securityTokenVersion.patch);
    }
    function unarchiveModule(address _module) external {
        _onlyOwner();
        TokenLib.unarchiveModule(moduleRegistry, modulesToData[_module]);
    }
    function removeModule(address _module) external {
        _onlyOwner();
        TokenLib.removeModule(_module, modules, modulesToData, names);
    }
    function withdrawERC20(address _tokenContract, uint256 _value) external {
        _onlyOwner();
        IERC20 token = IERC20(_tokenContract);
        require(token.transfer(owner(), _value));
    }
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external {
        _onlyOwner();
        TokenLib.changeModuleBudget(_module, _change, _increase, polyToken, modulesToData);
    }
    function updateTokenDetails(string calldata _newTokenDetails) external {
        _onlyOwner();
        emit UpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }
    function changeGranularity(uint256 _granularity) external {
        _onlyOwner();
        require(_granularity != 0, "Invalid granularity");
        emit GranularityChanged(granularity, _granularity);
        granularity = _granularity;
    }
    function changeDataStore(address _dataStore) external {
        _onlyOwner();
        _zeroAddressCheck(_dataStore);
        dataStore = IDataStore(_dataStore);
    }
    function changeName(string calldata _name) external {
        _onlyOwner();
        require(bytes(_name).length > 0);
        emit UpdateTokenName(name, _name);
        name = _name;
    }
    function changeTreasuryWallet(address _wallet) external {
        _onlyOwner();
        _zeroAddressCheck(_wallet);
        emit TreasuryWalletChanged(dataStore.getAddress(TREASURY), _wallet);
        dataStore.setAddress(TREASURY, _wallet);
    }
    function _adjustInvestorCount(address _from, address _to, uint256 _value) internal {
        holderCount = TokenLib.adjustInvestorCount(holderCount, _from, _to, _value, balanceOf(_to), balanceOf(_from), dataStore);
    }
    function freezeTransfers() external {
        _onlyOwner();
        require(!transfersFrozen);
        transfersFrozen = true;
        emit FreezeTransfers(true);
    }
    function unfreezeTransfers() external {
        _onlyOwner();
        require(transfersFrozen);
        transfersFrozen = false;
        emit FreezeTransfers(false);
    }
    function _adjustBalanceCheckpoints(address _investor) internal {
        TokenLib.adjustCheckpoints(checkpointBalances[_investor], balanceOf(_investor), currentCheckpointId);
    }
    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transferWithData(msg.sender, _to, _value, "");
        return true;
    }
    function transferWithData(address _to, uint256 _value, bytes memory _data) public {
        _transferWithData(msg.sender, _to, _value, _data);
    }
    function _transferWithData(address _from, address _to, uint256 _value, bytes memory _data) internal {
        _isValidTransfer(_updateTransfer(_from, _to, _value, _data));
        _transfer(_from, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        transferFromWithData(_from, _to, _value, "");
        return true;
    }
    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) public {
        _isValidTransfer(_updateTransfer(_from, _to, _value, _data));
        require(super.transferFrom(_from, _to, _value));
    }
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) public view returns(uint256) {
        return _balanceOfByPartition(_partition, _tokenHolder, 0);
    }
    function _balanceOfByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) internal view returns(uint256 partitionBalance) {
        address[] memory tms = modules[TRANSFER_KEY];
        uint256 amount;
        for (uint256 i = 0; i < tms.length; i++) {
            amount = ITransferManager(tms[i]).getTokensByPartition(_partition, _tokenHolder, _additionalBalance);
            if (_partition == UNLOCKED) {
                if (amount < partitionBalance || i == 0)
                    partitionBalance = amount;
            }
            else {
                if (partitionBalance < amount)
                    partitionBalance = amount;
            }
        }
    }
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes memory _data) public returns (bytes32) {
        return _transferByPartition(msg.sender, _to, _value, _partition, _data, address(0), "");
    }
    function _transferByPartition(
        address _from,
        address _to,
        uint256 _value,
        bytes32 _partition,
        bytes memory _data,
        address _operator,
        bytes memory _operatorData
    )
        internal
        returns(bytes32 toPartition)
    {
        _isValidPartition(_partition);
        uint256 lockedBalanceBeforeTransfer = _balanceOfByPartition(LOCKED, _to, 0);
        _transferWithData(_from, _to, _value, _data);
        uint256 lockedBalanceAfterTransfer = _balanceOfByPartition(LOCKED, _to, 0);
        toPartition =  _returnPartition(lockedBalanceBeforeTransfer, lockedBalanceAfterTransfer, _value);
        emit TransferByPartition(_partition, _operator, _from, _to, _value, _data, _operatorData);
    }
    function _returnPartition(uint256 _beforeBalance, uint256 _afterBalance, uint256 _value) internal pure returns(bytes32 toPartition) {
        toPartition = _afterBalance.sub(_beforeBalance) == _value ? LOCKED : UNLOCKED;
    }
    function authorizeOperator(address _operator) public {
        _approve(msg.sender, _operator, uint(-1));
        emit AuthorizedOperator(_operator, msg.sender);
    }
    function revokeOperator(address _operator) public {
        _approve(msg.sender, _operator, 0);
        emit RevokedOperator(_operator, msg.sender);
    }
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) public {
        _isValidPartition(_partition);
        partitionApprovals[msg.sender][_partition][_operator] = true;
        emit AuthorizedOperatorByPartition(_partition, _operator, msg.sender);
    }
    function revokeOperatorByPartition(bytes32 _partition, address _operator) public {
        _isValidPartition(_partition);
        partitionApprovals[msg.sender][_partition][_operator] = false;
        emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
    }
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32)
    {
        _validateOperatorAndPartition(_partition, _from, msg.sender);
        require(_operatorData[0] != 0);
        return _transferByPartition(_from, _to, _value, _partition, _data, msg.sender, _operatorData);
    }
    function _validateOperatorAndPartition(bytes32 _partition, address _from, address _operator) internal view {
        _isValidPartition(_partition);
        _isValidOperator(_from, _operator, _partition);
    }
    function _updateTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal nonReentrant returns(bool verified) {
        _adjustInvestorCount(_from, _to, _value);
        verified = _executeTransfer(_from, _to, _value, _data);
        _adjustBalanceCheckpoints(_from);
        _adjustBalanceCheckpoints(_to);
    }
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    )
        internal
        checkGranularity(_value)
        returns(bool)
    {
        if (!transfersFrozen) {
            bool isInvalid;
            bool isValid;
            bool isForceValid;
            address module;
            uint256 tmLength = modules[TRANSFER_KEY].length;
            for (uint256 i = 0; i < tmLength; i++) {
                module = modules[TRANSFER_KEY][i];
                if (!modulesToData[module].isArchived) {
                    ITransferManager.Result valid = ITransferManager(module).executeTransfer(_from, _to, _value, _data);
                    if (valid == ITransferManager.Result.INVALID) {
                        isInvalid = true;
                    } else if (valid == ITransferManager.Result.VALID) {
                        isValid = true;
                    } else if (valid == ITransferManager.Result.FORCE_VALID) {
                        isForceValid = true;
                    }
                }
            }
            return isForceValid ? true : (isInvalid ? false : isValid);
        }
        return false;
    }
    function freezeIssuance(bytes calldata _signature) external {
        _onlyOwner();
        _isIssuanceAllowed();
        _isSignedByOwner(owner() == TokenLib.recoverFreezeIssuanceAckSigner(_signature));
        issuance = false;
        emit FreezeIssuance();
    }
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    )
        public
    {
        _isIssuanceAllowed();
        _onlyModuleOrOwner(MINT_KEY);
        _issue(_tokenHolder, _value, _data);
    }
    function _issue(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    )
        internal
    {
        _isValidTransfer(_updateTransfer(address(0), _tokenHolder, _value, _data));
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }
    function issueMulti(address[] memory _tokenHolders, uint256[] memory _values) public {
        _isIssuanceAllowed();
        _onlyModuleOrOwner(MINT_KEY);
        require(_tokenHolders.length == _values.length);
        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            _issue(_tokenHolders[i], _values[i], "");
        }
    }
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external {
        _isValidPartition(_partition);
        issue(_tokenHolder, _value, _data);
        emit IssuedByPartition(_partition, _tokenHolder, _value, _data);
    }
    function redeem(uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        _redeem(msg.sender, _value, _data);
    }
    function _redeem(address _from, uint256 _value, bytes memory _data) internal {
        _isValidRedeem(_checkAndBurn(_from, _value, _data));
    }
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        _isValidPartition(_partition);
        _redeemByPartition(_partition, msg.sender, _value, address(0), _data, "");
    }
    function _redeemByPartition(
        bytes32 _partition,
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
    {
        _redeem(_from, _value, _data);
        emit RedeemedByPartition(_partition, _operator, _from, _value, _data, _operatorData);
    }
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
    {
        _onlyModule(BURN_KEY);
        require(_operatorData[0] != 0);
        _zeroAddressCheck(_tokenHolder);
        _validateOperatorAndPartition(_partition, _tokenHolder, msg.sender);
        _redeemByPartition(_partition, _tokenHolder, _value, msg.sender, _data, _operatorData);
    }
    function _checkAndBurn(address _from, uint256 _value, bytes memory _data) internal returns(bool verified) {
        verified = _updateTransfer(_from, address(0), _value, _data);
        _burn(_from, _value);
        emit Redeemed(address(0), msg.sender, _value, _data);
    }
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        _isValidRedeem(_updateTransfer(_tokenHolder, address(0), _value, _data));
        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }
    function createCheckpoint() external returns(uint256) {
        _onlyModuleOrOwner(CHECKPOINT_KEY);
        currentCheckpointId = currentCheckpointId + 1;
        checkpointTimes.push(now);
        checkpointTotalSupply[currentCheckpointId] = totalSupply();
        emit CheckpointCreated(currentCheckpointId, dataStore.getAddressArrayLength(INVESTORSKEY));
        return currentCheckpointId;
    }
    function setController(address _controller) external {
        _onlyOwner();
        require(isControllable());
        emit SetController(controller, _controller);
        controller = _controller;
    }
    function disableController(bytes calldata _signature) external {
        _onlyOwner();
        _isSignedByOwner(owner() == TokenLib.recoverDisableControllerAckSigner(_signature));
        require(isControllable());
        controllerDisabled = true;
        delete controller;
        emit DisableController();
    }
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32) {
        return _canTransfer(msg.sender, _to, _value, _data);
    }
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte reasonCode, bytes32 appCode) {
        (reasonCode, appCode) = _canTransfer(_from, _to, _value, _data);
        if (_isSuccess(reasonCode) && _value > allowance(_from, msg.sender)) {
            return (StatusCodes.code(StatusCodes.Status.InsufficientAllowance), bytes32(0));
        }
    }
    function _canTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal view returns (byte, bytes32) {
        bytes32 appCode;
        bool success;
        if (_value % granularity != 0) {
            return (StatusCodes.code(StatusCodes.Status.TransferFailure), bytes32(0));
        }
        (success, appCode) = TokenLib.verifyTransfer(modules[TRANSFER_KEY], modulesToData, _from, _to, _value, _data, transfersFrozen);
        return TokenLib.canTransfer(success, appCode, _to, _value, balanceOf(_from));
    }
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte reasonCode, bytes32 appStatusCode, bytes32 toPartition)
    {
        if (_partition == UNLOCKED) {
            (reasonCode, appStatusCode) = _canTransfer(_from, _to, _value, _data);
            if (_isSuccess(reasonCode)) {
                uint256 beforeBalance = _balanceOfByPartition(LOCKED, _to, 0);
                uint256 afterbalance = _balanceOfByPartition(LOCKED, _to, _value);
                toPartition = _returnPartition(beforeBalance, afterbalance, _value);
            }
            return (reasonCode, appStatusCode, toPartition);
        }
        return (StatusCodes.code(StatusCodes.Status.TransferFailure), bytes32(0), bytes32(0));
    }
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external {
        _onlyOwner();
        TokenLib.setDocument(_documents, _docNames, _docIndexes, _name, _uri, _documentHash);
    }
    function removeDocument(bytes32 _name) external {
        _onlyOwner();
        TokenLib.removeDocument(_documents, _docNames, _docIndexes, _name);
    }
    function isControllable() public view returns (bool) {
        return !controllerDisabled;
    }
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external {
        _onlyController();
        _updateTransfer(_from, _to, _value, _data);
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external {
        _onlyController();
        _checkAndBurn(_tokenHolder, _value, _data);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }
    function _implementation() internal view returns(address) {
        return getterDelegate;
    }
    function updateFromRegistry() public {
        _onlyOwner();
        moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        securityTokenRegistry = ISecurityTokenRegistry(polymathRegistry.getAddress("SecurityTokenRegistry"));
        polyToken = IERC20(polymathRegistry.getAddress("PolyToken"));
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) external {
        _onlyOwner();
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function _isSuccess(byte status) internal pure returns (bool successful) {
        return (status & 0x0F) == 0x01;
    }
}