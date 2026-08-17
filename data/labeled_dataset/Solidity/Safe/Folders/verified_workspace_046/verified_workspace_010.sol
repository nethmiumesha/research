pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "../Permissions.sol";
import "../ConstantsHolder.sol";
import "./DelegationController.sol";
import "./TimeHelpers.sol";
contract ValidatorService is Permissions {
    using ECDSA for bytes32;
    struct Validator {
        string name;
        address validatorAddress;
        address requestedAddress;
        string description;
        uint feeRate;
        uint registrationTime;
        uint minimumDelegationAmount;
        bool acceptNewRequests;
    }
    event ValidatorRegistered(
        uint validatorId
    );
    event ValidatorAddressChanged(
        uint validatorId,
        address newAddress
    );
    event ValidatorWasEnabled(
        uint validatorId
    );
    event ValidatorWasDisabled(
        uint validatorId
    );
    event NodeAddressWasAdded(
        uint validatorId,
        address nodeAddress
    );
    event NodeAddressWasRemoved(
        uint validatorId,
        address nodeAddress
    );
    mapping (uint => Validator) public validators;
    mapping (uint => bool) private _trustedValidators;
    uint[] public trustedValidatorsList;
    mapping (address => uint) private _validatorAddressToId;
    mapping (address => uint) private _nodeAddressToValidatorId;
    mapping (uint => address[]) private _nodeAddresses;
    uint public numberOfValidators;
    bool public useWhitelist;
    modifier checkValidatorExists(uint validatorId) {
        require(validatorExists(validatorId), "Validator with such ID does not exist");
        _;
    }
    function registerValidator(
        string calldata name,
        string calldata description,
        uint feeRate,
        uint minimumDelegationAmount
    )
        external
        returns (uint validatorId)
    {
        require(!validatorAddressExists(msg.sender), "Validator with such address already exists");
        require(feeRate <= 1000, "Fee rate of validator should be lower than 100%");
        validatorId = ++numberOfValidators;
        validators[validatorId] = Validator(
            name,
            msg.sender,
            address(0),
            description,
            feeRate,
            now,
            minimumDelegationAmount,
            true
        );
        _setValidatorAddress(validatorId, msg.sender);
        emit ValidatorRegistered(validatorId);
    }
    function enableValidator(uint validatorId) external checkValidatorExists(validatorId) onlyAdmin {
        require(!_trustedValidators[validatorId], "Validator is already enabled");
        _trustedValidators[validatorId] = true;
        trustedValidatorsList.push(validatorId);
        emit ValidatorWasEnabled(validatorId);
    }
    function disableValidator(uint validatorId) external checkValidatorExists(validatorId) onlyAdmin {
        require(_trustedValidators[validatorId], "Validator is already disabled");
        _trustedValidators[validatorId] = false;
        uint position = _find(trustedValidatorsList, validatorId);
        if (position < trustedValidatorsList.length) {
            trustedValidatorsList[position] =
                trustedValidatorsList[trustedValidatorsList.length.sub(1)];
        }
        trustedValidatorsList.pop();
        emit ValidatorWasDisabled(validatorId);
    }
    function disableWhitelist() external onlyOwner {
        useWhitelist = false;
    }
    function requestForNewAddress(address newValidatorAddress) external {
        require(newValidatorAddress != address(0), "New address cannot be null");
        require(_validatorAddressToId[newValidatorAddress] == 0, "Address already registered");
        uint validatorId = getValidatorId(msg.sender);
        validators[validatorId].requestedAddress = newValidatorAddress;
    }
    function confirmNewAddress(uint validatorId)
        external
        checkValidatorExists(validatorId)
    {
        require(
            getValidator(validatorId).requestedAddress == msg.sender,
            "The validator address cannot be changed because it is not the actual owner"
        );
        delete validators[validatorId].requestedAddress;
        _setValidatorAddress(validatorId, msg.sender);
        emit ValidatorAddressChanged(validatorId, validators[validatorId].validatorAddress);
    }
    function linkNodeAddress(address nodeAddress, bytes calldata sig) external {
        uint validatorId = getValidatorId(msg.sender);
        require(
            keccak256(abi.encodePacked(validatorId)).toEthSignedMessageHash().recover(sig) == nodeAddress,
            "Signature is not pass"
        );
        require(_validatorAddressToId[nodeAddress] == 0, "Node address is a validator");
        _addNodeAddress(validatorId, nodeAddress);
        emit NodeAddressWasAdded(validatorId, nodeAddress);
    }
    function unlinkNodeAddress(address nodeAddress) external {
        uint validatorId = getValidatorId(msg.sender);
        this.removeNodeAddress(validatorId, nodeAddress);
        emit NodeAddressWasRemoved(validatorId, nodeAddress);
    }
    function setValidatorMDA(uint minimumDelegationAmount) external {
        uint validatorId = getValidatorId(msg.sender);
        validators[validatorId].minimumDelegationAmount = minimumDelegationAmount;
    }
    function setValidatorName(string calldata newName) external {
        uint validatorId = getValidatorId(msg.sender);
        validators[validatorId].name = newName;
    }
    function setValidatorDescription(string calldata newDescription) external {
        uint validatorId = getValidatorId(msg.sender);
        validators[validatorId].description = newDescription;
    }
    function startAcceptingNewRequests() external {
        uint validatorId = getValidatorId(msg.sender);
        require(!isAcceptingNewRequests(validatorId), "Accepting request is already enabled");
        validators[validatorId].acceptNewRequests = true;
    }
    function stopAcceptingNewRequests() external {
        uint validatorId = getValidatorId(msg.sender);
        require(isAcceptingNewRequests(validatorId), "Accepting request is already disabled");
        validators[validatorId].acceptNewRequests = false;
    }
    function removeNodeAddress(uint validatorId, address nodeAddress) external allowTwo("ValidatorService", "Nodes") {
        require(_nodeAddressToValidatorId[nodeAddress] == validatorId,
            "Validator does not have permissions to unlink node");
        delete _nodeAddressToValidatorId[nodeAddress];
        for (uint i = 0; i < _nodeAddresses[validatorId].length; ++i) {
            if (_nodeAddresses[validatorId][i] == nodeAddress) {
                if (i + 1 < _nodeAddresses[validatorId].length) {
                    _nodeAddresses[validatorId][i] =
                        _nodeAddresses[validatorId][_nodeAddresses[validatorId].length.sub(1)];
                }
                delete _nodeAddresses[validatorId][_nodeAddresses[validatorId].length.sub(1)];
                _nodeAddresses[validatorId].pop();
                break;
            }
        }
    }
    function getAndUpdateBondAmount(uint validatorId)
        external
        returns (uint)
    {
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController")
        );
        return delegationController.getAndUpdateDelegatedByHolderToValidatorNow(
            getValidator(validatorId).validatorAddress,
            validatorId
        );
    }
    function getMyNodesAddresses() external view returns (address[] memory) {
        return getNodeAddresses(getValidatorId(msg.sender));
    }
    function getTrustedValidators() external view returns (uint[] memory) {
        return trustedValidatorsList;
    }
    function checkValidatorAddressToId(address validatorAddress, uint validatorId)
        external
        view
        returns (bool)
    {
        return getValidatorId(validatorAddress) == validatorId ? true : false;
    }
    function getValidatorIdByNodeAddress(address nodeAddress) external view returns (uint validatorId) {
        validatorId = _nodeAddressToValidatorId[nodeAddress];
        require(validatorId != 0, "Node address is not assigned to a validator");
    }
    function checkValidatorCanReceiveDelegation(uint validatorId, uint amount) external view {
        require(isAuthorizedValidator(validatorId), "Validator is not authorized to accept delegation request");
        require(isAcceptingNewRequests(validatorId), "The validator is not currently accepting new requests");
        require(
            validators[validatorId].minimumDelegationAmount <= amount,
            "Amount does not meet the validator's minimum delegation amount"
        );
    }
    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
        useWhitelist = true;
    }
    function getNodeAddresses(uint validatorId) public view returns (address[] memory) {
        return _nodeAddresses[validatorId];
    }
    function validatorExists(uint validatorId) public view returns (bool) {
        return validatorId <= numberOfValidators && validatorId != 0;
    }
    function validatorAddressExists(address validatorAddress) public view returns (bool) {
        return _validatorAddressToId[validatorAddress] != 0;
    }
    function checkIfValidatorAddressExists(address validatorAddress) public view {
        require(validatorAddressExists(validatorAddress), "Validator address does not exist");
    }
    function getValidator(uint validatorId) public view checkValidatorExists(validatorId) returns (Validator memory) {
        return validators[validatorId];
    }
    function getValidatorId(address validatorAddress) public view returns (uint) {
        checkIfValidatorAddressExists(validatorAddress);
        return _validatorAddressToId[validatorAddress];
    }
    function isAcceptingNewRequests(uint validatorId) public view checkValidatorExists(validatorId) returns (bool) {
        return validators[validatorId].acceptNewRequests;
    }
    function isAuthorizedValidator(uint validatorId) public view checkValidatorExists(validatorId) returns (bool) {
        return _trustedValidators[validatorId] || !useWhitelist;
    }
    function _setValidatorAddress(uint validatorId, address validatorAddress) private {
        if (_validatorAddressToId[validatorAddress] == validatorId) {
            return;
        }
        require(_validatorAddressToId[validatorAddress] == 0, "Address is in use by another validator");
        address oldAddress = validators[validatorId].validatorAddress;
        delete _validatorAddressToId[oldAddress];
        _nodeAddressToValidatorId[validatorAddress] = validatorId;
        validators[validatorId].validatorAddress = validatorAddress;
        _validatorAddressToId[validatorAddress] = validatorId;
    }
    function _addNodeAddress(uint validatorId, address nodeAddress) private {
        if (_nodeAddressToValidatorId[nodeAddress] == validatorId) {
            return;
        }
        require(_nodeAddressToValidatorId[nodeAddress] == 0, "Validator cannot override node address");
        _nodeAddressToValidatorId[nodeAddress] = validatorId;
        _nodeAddresses[validatorId].push(nodeAddress);
    }
    function _find(uint[] memory array, uint index) private pure returns (uint) {
        uint i;
        for (i = 0; i < array.length; i++) {
            if (array[i] == index) {
                return i;
            }
        }
        return array.length;
    }
}