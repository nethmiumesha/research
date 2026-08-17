 pragma solidity 0.5.0;
library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}
interface ERC165 {
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  mapping(bytes4 => bool) internal supportedInterfaces;
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}
contract ERC721Receiver {
  bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    returns(bytes4);
}
contract ERC721Basic is ERC165 {
  event Transfer(
    address  _from,
    address  _to,
    uint256  _tokenId
  );
  event Approval(
    address  _owner,
    address  _approved,
    uint256  _tokenId
  );
  event ApprovalForAll(
    address  _owner,
    address  _operator,
    bool _approved
  );
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);
  function transferFrom(address _from, address _to, uint256 _tokenId) public returns(bool);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public;
}
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {
  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
  using SafeMath for uint256;
  using AddressUtils for address;
  bytes4 private constant ERC721_RECEIVED = 0xf0b9e5ba;
  mapping (uint256 => address) internal tokenOwner;
  mapping (uint256 => address) internal tokenApprovals;
  mapping (address => uint256) internal ownedTokensCount;
  mapping (address => mapping (address => bool)) internal operatorApprovals;
  uint public testint;
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
    returns(bool)
  {
    require(_from != address(0));
    require(_to != address(0));
    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
    return true;
  }
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}
contract ERC721BasicTokenMock is ERC721BasicToken {
  function mint(address _to, uint256 _tokenId) public {
    super._mint(_to, _tokenId);
  }
  function burn(uint256 _tokenId) public {
    super._burn(ownerOf(_tokenId), _tokenId);
  }
}