pragma solidity ^0.4.25;
interface BasicJurisdictionInterface {
  event AttributeTypeAdded(uint256 indexed attributeTypeID, string description);
  event AttributeTypeRemoved(uint256 indexed attributeTypeID);
  event ValidatorAdded(address indexed validator, string description);
  event ValidatorRemoved(address indexed validator);
  event ValidatorApprovalAdded(
    address validator,
    uint256 indexed attributeTypeID
  );
  event ValidatorApprovalRemoved(
    address validator,
    uint256 indexed attributeTypeID
  );
  event AttributeAdded(
    address validator,
    address indexed attributee,
    uint256 attributeTypeID,
    uint256 attributeValue
  );
  event AttributeRemoved(
    address validator,
    address indexed attributee,
    uint256 attributeTypeID
  );
  function addAttributeType(uint256 ID, string description) external;
  function removeAttributeType(uint256 ID) external;
  function addValidator(address validator, string description) external;
  function removeValidator(address validator) external;
  function addValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external;
  function removeValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external;
  function issueAttribute(
    address account,
    uint256 attributeTypeID,
    uint256 value
  ) external payable;
  function revokeAttribute(
    address account,
    uint256 attributeTypeID
  ) external;
  function canIssueAttributeType(
    address validator,
    uint256 attributeTypeID
  ) external view returns (bool);
  function getAttributeTypeDescription(
    uint256 attributeTypeID
  ) external view returns (string description);
  function getValidatorDescription(
    address validator
  ) external view returns (string description);
  function getAttributeValidator(
    address account,
    uint256 attributeTypeID
  ) external view returns (address validator, bool isStillValid);
  function countAttributeTypes() external view returns (uint256);
  function getAttributeTypeID(uint256 index) external view returns (uint256);
  function getAttributeTypeIDs() external view returns (uint256[]);
  function countValidators() external view returns (uint256);
  function getValidator(uint256 index) external view returns (address);
  function getValidators() external view returns (address[]);
}