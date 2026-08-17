pragma solidity 0.8.10;
import "chainlink/VRFConsumerBase.sol";
import "../utils/Errors.sol";
import "../interfaces/IRegistry.sol";
contract RNG is VRFConsumerBase {
  IRegistry registry;
  string constant ERR_REQ_ALR_FULFILLED = "Request already fulfilled";
  string constant ERR_REQ_NOT_FULFILLED = "Request isn't fulfilled";
  string constant ERR_RAND_NOT_READY = "Random number isn't ready";
  string constant ERR_RAND_EMPTY = "Random number is empty, request again";
  string constant ERR_ENOUGH_LINK = "Not enough LINK in contract";
  bytes32 private keyHash;
  uint256 private fee;
  event ChainlinkRandomFulfilled(address caller);
  event BlockRandomFulfilled(address caller);
  struct BlockRandom {
    bool fulfilled;
    uint256 blockNum;
    uint256 num;
  }
  mapping(address => BlockRandom) userToBlockRandom;
  mapping(bytes32 => address) clRequestToUser;
  mapping(address => uint256) userToClRandom;
  modifier authorized() {
    require(registry.authorized(msg.sender), "Not authorized");
    _;
  }
  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee,
    IRegistry registryAddress
  ) VRFConsumerBase(_vrfCoordinator, _link) {
    keyHash = _keyHash;
    fee = _fee;
    registry = IRegistry(registryAddress);
  }
  function requestBlockRandom(address caller) external authorized {
    userToBlockRandom[caller] = BlockRandom({fulfilled: true, blockNum: block.number, num: 0});
  }
  function checkBlockRandom(address caller) external {
    require(userToBlockRandom[caller].fulfilled, Errors.REQ_NOT_FULFILLED);
    uint256 prevBlockNum = userToBlockRandom[caller].blockNum;
    require(block.number - prevBlockNum <= 256, Errors.REQ_LATE);
    require(prevBlockNum < block.number, Errors.RAND_NOT_READY);
    if (block.number - prevBlockNum <= 256) {
      userToBlockRandom[caller].num = uint256(
        keccak256(abi.encodePacked(blockhash(prevBlockNum), caller))
      );
      emit BlockRandomFulfilled(caller);
    }
    userToBlockRandom[caller].fulfilled = false;
  }
  function getBlockRandom(address caller) external view returns (uint256) {
    require(userToBlockRandom[caller].num != 0, Errors.RAND_EMPTY);
    return userToBlockRandom[caller].num;
  }
  function resetBlockRandom(address caller) external authorized {
    delete userToBlockRandom[caller];
  }
  function requestChainlinkRandom(address caller)
    external
    authorized
    returns (bytes32 requestId)
  {
    require(LINK.balanceOf(address(this)) >= fee, Errors.ENOUGH_LINK);
    requestId = requestRandomness(keyHash, fee);
    clRequestToUser[requestId] = caller;
  }
  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    address requestAddress = clRequestToUser[_requestId];
    require(requestAddress != address(0), Errors.REQ_NOT_FULFILLED);
    userToClRandom[requestAddress] = _randomness;
    emit ChainlinkRandomFulfilled(requestAddress);
    delete clRequestToUser[_requestId];
  }
  function getChainlinkRandom(address caller) external view returns (uint256) {
    require(userToClRandom[caller] != 0, Errors.RAND_EMPTY);
    return userToClRandom[caller];
  }
  function resetChainlinkRandom(address caller) external authorized {
    delete userToClRandom[caller];
  }
}