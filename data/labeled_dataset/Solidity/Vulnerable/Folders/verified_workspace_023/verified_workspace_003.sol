pragma solidity 0.8.4;
import "../lib/LibAsset.sol";
contract LibAssetTest {
  constructor() {}
  receive() external payable {}
  function isNativeAsset(address assetId) public pure returns (bool) {
    return LibAsset.isNativeAsset(assetId);
  }
  function getOwnBalance(address assetId) public view returns (uint256) {
    return LibAsset.getOwnBalance(assetId);
  }
  function transferNativeAsset(address payable recipient, uint256 amount) public {
    LibAsset.transferNativeAsset(recipient, amount);
  }
  function increaseERC20Allowance(address assetId, address spender, uint256 amount) public {
    LibAsset.increaseERC20Allowance(assetId, spender, amount);
  }
  function decreaseERC20Allowance(address assetId, address spender, uint256 amount) public {
    LibAsset.decreaseERC20Allowance(assetId, spender, amount);
  }
  function transferERC20(
    address assetId,
    address recipient,
    uint256 amount
  ) public {
    LibAsset.transferERC20(assetId, recipient, amount);
  }
  function transferAsset(
    address assetId,
    address payable recipient,
    uint256 amount
  ) public {
    LibAsset.transferAsset(assetId, recipient, amount);
  }
}