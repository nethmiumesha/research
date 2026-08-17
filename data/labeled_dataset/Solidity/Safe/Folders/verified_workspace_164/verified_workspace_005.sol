pragma solidity ^0.4.24;
interface ExtendedJurisdictionInterface {
  event ValidatorSigningKeyModified(
    address indexed validator,
    address newSigningKey
  );
  event StakeAllocated(
    address indexed staker,
    uint256 indexed attribute,
    uint256 amount
  );
  event StakeRefunded(
    address indexed staker,
    uint256 indexed attribute,
    uint256 amount
  );
  event FeePaid(
    address indexed recipient,
    address indexed payee,
    uint256 indexed attribute,
    uint256 amount
  );
  event TransactionRebatePaid(
    address indexed submitter,
    address indexed payee,
    uint256 indexed attribute,
    uint256 amount
  );
  function addRestrictedAttributeType(uint256 ID, string description) external;
  function setAttributeTypeOnlyPersonal(uint256 ID, bool onlyPersonal) external;
  function setAttributeTypeSecondarySource(
    uint256 ID,
    address attributeRegistry,
    uint256 sourceAttributeTypeID
  ) external;
  function setAttributeTypeMinimumRequiredStake(
    uint256 ID,
    uint256 minimumRequiredStake
  ) external;
  function setAttributeTypeJurisdictionFee(uint256 ID, uint256 fee) external;
  function setValidatorSigningKey(address newSigningKey) external;
  function addAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable;
  function removeAttribute(uint256 attributeTypeID) external;
  function addAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable;
  function removeAttributeFor(address account, uint256 attributeTypeID) external;
  function invalidateAttributeApproval(
    bytes32 hash,
    bytes signature
  ) external;
  function getAttributeApprovalHash(
    address account,
    address operator,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee
  ) external view returns (bytes32 hash);
  function canAddAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool);
  function canAddAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool);
  function getAttributeTypeInformation(
    uint256 attributeTypeID
  ) external view returns (
    string description,
    bool isRestricted,
    bool isOnlyPersonal,
    address secondarySource,
    uint256 secondaryId,
    uint256 minimumRequiredStake,
    uint256 jurisdictionFee
  );
  function getValidatorSigningKey(
    address validator
  ) external view returns (
    address signingKey
  );
}