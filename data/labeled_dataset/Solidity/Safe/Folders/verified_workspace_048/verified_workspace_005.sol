pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "../utils/Ownable.sol";
import "../interfaces/ISWSupplyManager.sol";
import "multi-token-standard/contracts/interfaces/IERC1155.sol";
import "multi-token-standard/contracts/utils/SafeMath.sol";
contract WeaveFactory is Ownable {
  using SafeMath for uint256;
  ISWSupplyManager internal factoryManager;
  uint256 internal weavePerSecond;
  uint256 internal lastHarvest;
  uint256 internal weaveID;
  event WeaveHarvested(address recipient, uint256 amount);
  constructor(address _factoryManagerAddr, uint256 _weavePerSecond, uint256 _weaveID) public {
    require(
      _factoryManagerAddr != address(0),
      "WeaveFactory#constructor: INVALID_INPUT"
    );
    factoryManager = ISWSupplyManager(_factoryManagerAddr);
    weavePerSecond = _weavePerSecond;
    lastHarvest = now;
    weaveID = _weaveID;
  }
  function harvestWeave(address _recipient, bytes calldata _data) external onlyOwner() {
    uint256 time_since_last_harvest = now.sub(lastHarvest);
    uint256 weave_to_harvest = time_since_last_harvest.mul(weavePerSecond);
    lastHarvest = now;
    factoryManager.mint(_recipient, weaveID, weave_to_harvest, _data);
    emit WeaveHarvested(_recipient, weave_to_harvest);
  }
  function () external {
    revert("UNSUPPORTED_METHOD");
  }
  function getFactoryManager() external view returns (address) {
    return address(factoryManager);
  }
  function getWeaveID() external view returns (uint256) {
    return weaveID;
  }
  function getWeavePerSecond() external view returns (uint256) {
    return weavePerSecond;
  }
  function getLastHarvest() external view returns (uint256) {
    return lastHarvest;
  }
  function getAvailableWeave() external view returns (uint256) {
    uint256 time_since_last_harvest = now.sub(lastHarvest);
    return time_since_last_harvest.mul(weavePerSecond);
  }
}