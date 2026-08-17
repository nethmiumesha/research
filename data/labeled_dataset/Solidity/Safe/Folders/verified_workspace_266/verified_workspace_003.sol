pragma solidity ^0.4.6;
import "./StateTransferrable.sol";
contract Namereg is StateTransferrable {
  event NameRegistered(bytes32 indexed name, address indexed addr, address indexed owner);
  event NameUnregistered(bytes32 indexed name);
  struct Record {
    address record;
    address owner;
    bool initialized;
  }
  mapping (bytes32 => Record) public registry;
  mapping (address => bytes32) public lookupTable;
  bytes32[] public registryIndex;
  mapping (bytes32 => bool) public registryActive;
  address[] public lookupIndex;
  mapping (address => bool) public lookupActive;
  function registerImpl(bytes32 name, address addr, address owner) internal returns (bool success) {
    activateName(name);
    activateAddress(addr);
    registry[name].record = addr;
    registry[name].owner = owner;
    registry[name].initialized = true;
    NameRegistered(name, addr, owner);
    return true;
  }
  function registerImplChecked(bytes32 name, address addr, address owner) internal returns (bool success) {
    assert(registry[name].initialized && registry[name].record == address(0x0) || registry[name].owner == owner);
    return registerImpl(name, addr, owner);
  }
  function unregisterImpl(bytes32 name, address caller) internal returns (bool success) {
    assert(registry[name].owner == caller);
    delete registry[name];
    NameUnregistered(name);
    return true;
  }
  function register(bytes32 name, address addr) returns (bool success) {
    return registerImplChecked(name, addr, msg.sender);
  }
  function unregister(bytes32 name) returns (bool success) {
    return unregisterImpl(name, msg.sender);
  }
  function unregisterAddr(address addr) onlyOwner returns (bool success) {
    bytes32 name = lookupTable[addr];
    return unregisterImpl(name, msg.sender);
  }
  function resolve(bytes32 name) constant returns (address result) {
    return registry[name].record;
  }
  function getName(address addr) returns (bytes32 result) {
    return lookupTable[addr];
  }
  function registerSelf(bytes32 name) returns (bool success) {
    assert(!registry[name].initialized || registry[name].owner == msg.sender);
    return registerImpl(name, msg.sender, msg.sender);
  }
  function extractRegistryIndexLength() returns (uint256 len) {
    return registryIndex.length;
  }
  function extractLookupIndexLength() returns (uint256 len) {
    return lookupIndex.length;
  }
  function extractRegistryRecord(bytes32 key) returns (address record) {
    return registry[key].record;
  }
  function extractRegistryOwner(bytes32 key) returns (address owner) {
    return registry[key].owner;
  }
  function extractRegistryInitialized(bytes32 key) returns (bool initialized) {
    return registry[key].initialized;
  }
  function activateName(bytes32 name) internal {
    if (!registryActive[name]) {
      registryActive[name] = true;
      registryIndex.push(name);
    }
  }
  function activateAddress(address addr) internal {
    if (!lookupActive[addr]) {
      lookupActive[addr] = true;
      lookupIndex.push(addr);
    }
  }
}