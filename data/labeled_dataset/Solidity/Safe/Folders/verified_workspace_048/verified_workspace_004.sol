pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "../utils/Ownable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "../abstract/AbstractERC1155MintBurn.sol";
import "multi-token-standard/contracts/interfaces/IERC1155.sol";
import "multi-token-standard/contracts/tokens/ERC1155/ERC1155Metadata.sol";
import "multi-token-standard/contracts/utils/SafeMath.sol";
contract SWSupplyManager is IERC1155, AbstractERC1155MintBurn, ERC1155Metadata, Ownable {
  using SafeMath for uint256;
  mapping(address => bool) internal isFactoryActive;
  mapping(address => AssetRange[]) internal mintAccessRanges;
  AssetRange[] internal lockedRanges;
  mapping (uint256 => uint256) internal currentSupply;
  mapping (uint256 => uint256) internal maxSupply;
  struct AssetRange {
    uint256 minID;
    uint256 maxID;
  }
  event FactoryActivation(address indexed factory);
  event FactoryShutdown(address indexed factory);
  event MaxSuppliesChanged(uint256[] ids, uint256[] newMaxSupplies);
  event MintPermissionAdded(address indexed factory, AssetRange new_range);
  event MintPermissionRemoved(address indexed factory, AssetRange deleted_range);
  event RangeLocked(AssetRange locked_range);
  function activateFactory(address _factory) external onlyOwner() {
    isFactoryActive[_factory] = true;
    emit FactoryActivation(_factory);
  }
  function shutdownFactory(address _factory) external onlyOwner() {
    isFactoryActive[_factory] = false;
    emit FactoryShutdown(_factory);
  }
  function addMintPermission(address _factory, uint256 _minRange, uint256 _maxRange) external onlyOwner() {
    require(_maxRange > 0, "SWSupplyManager#addMintPermission: NULL_RANGE");
    require(_minRange <= _maxRange, "SWSupplyManager#addMintPermission: INVALID_RANGE");
    for (uint256 i = 0; i < lockedRanges.length; i++) {
      AssetRange memory locked_range = lockedRanges[i];
      require(
        (_maxRange < locked_range.minID) || (locked_range.maxID < _minRange),
        "SWSupplyManager#addMintPermission: OVERLAP_WITH_LOCKED_RANGE"
      );
    }
    AssetRange memory range = AssetRange(_minRange, _maxRange);
    mintAccessRanges[_factory].push(range);
    emit MintPermissionAdded(_factory, range);
  }
  function removeMintPermission(address _factory, uint256 _rangeIndex) external onlyOwner() {
    uint256 last_index = mintAccessRanges[_factory].length - 1;
    AssetRange memory range_to_delete = mintAccessRanges[_factory][_rangeIndex];
    if (_rangeIndex != last_index) {
      AssetRange memory last_range = mintAccessRanges[_factory][last_index];
      mintAccessRanges[_factory][_rangeIndex] = last_range;
    }
    mintAccessRanges[_factory].length--;
    emit MintPermissionRemoved(_factory, range_to_delete);
  }
  function lockRangeMintPermissions(AssetRange memory _range) public onlyOwner() {
    lockedRanges.push(_range);
    emit RangeLocked(_range);
  }
  function setMaxSupplies(uint256[] calldata _ids, uint256[] calldata _newMaxSupplies) external onlyOwner() {
    require(_ids.length == _newMaxSupplies.length, "SWSupplyManager#setMaxSupply: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _ids.length; i++ ) {
      if (maxSupply[_ids[i]] > 0) {
        require(
          0 < _newMaxSupplies[i] && _newMaxSupplies[i] < maxSupply[_ids[i]],
          "SWSupplyManager#setMaxSupply: INVALID_NEW_MAX_SUPPLY"
        );
      }
      maxSupply[_ids[i]] = _newMaxSupplies[i];
    }
    emit MaxSuppliesChanged(_ids, _newMaxSupplies);
  }
  function () external {
    revert("UNSUPPORTED_METHOD");
  }
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data) public
  {
    _validateMints(_ids, _amounts);
    _batchMint(_to, _ids, _amounts, _data);
  }
  function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external
  {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;
    _validateMints(ids, amounts);
    _mint(_to, _id, _amount, _data);
  }
  function _validateMints(uint256[] memory _ids, uint256[] memory _amounts) internal {
    require(isFactoryActive[msg.sender], "SWSupplyManager#_validateMints: FACTORY_NOT_ACTIVE");
    uint256 n_ranges = mintAccessRanges[msg.sender].length;
    AssetRange memory range = mintAccessRanges[msg.sender][0];
    uint256 range_index = 0;
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      uint256 amount = _amounts[i];
      uint256 max_supply = maxSupply[id];
      while (id < range.minID || range.maxID < id) {
        range_index += 1;
        require(range_index < n_ranges, "SWSupplyManager#_validateMints: ID_OUT_OF_RANGE");
        range = mintAccessRanges[msg.sender][range_index];
      }
      if (max_supply > 0) {
        uint256 new_supply = currentSupply[id].add(amount);
        require(new_supply <= max_supply, "SWSupplyManager#_validateMints: MAX_SUPPLY_EXCEEDED");
        currentSupply[id] = new_supply;
      }
    }
  }
  function getMaxSupplies(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256 nIds = _ids.length;
    uint256[] memory maxSupplies = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      maxSupplies[i] = maxSupply[_ids[i]];
    }
    return maxSupplies;
  }
  function getCurrentSupplies(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256 nIds = _ids.length;
    uint256[] memory currentSupplies = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      currentSupplies[i] = currentSupply[_ids[i]];
    }
    return currentSupplies;
  }
  function getFactoryStatus(address _factory) external view returns (bool) {
    return isFactoryActive[_factory];
  }
  function getFactoryAccessRanges(address _factory) external view returns (AssetRange[] memory) {
    return mintAccessRanges[_factory];
  }
  function getLockedRanges() external view returns (AssetRange[] memory) {
    return lockedRanges;
  }
  function burn(
    uint256 _id,
    uint256 _amount)
    external
  {
    _burn(msg.sender, _id, _amount);
  }
  function batchBurn(
    uint256[] calldata _ids,
    uint256[] calldata _amounts)
    external
  {
    _batchBurn(msg.sender, _ids, _amounts);
  }
  function setBaseMetadataURI(string calldata _newBaseMetadataURI) external onlyOwner() {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }
  function logURIs(uint256[] calldata _tokenIDs) external onlyOwner() {
    _logURIs(_tokenIDs);
  }
}