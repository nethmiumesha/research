pragma solidity 0.4.18;
import "./WalletMainLib.sol";
library WalletGetterLib {
  function getOwners(WalletMainLib.WalletData storage self) public view returns (address[51]) {
    address[51] memory o;
    for(uint256 i = 0; i<self.owners.length; i++){
      o[i] = self.owners[i];
    }
    return o;
  }
  function getOwnerIndex(WalletMainLib.WalletData storage self, address _owner) public view returns (uint256) {
    return self.ownerIndex[_owner];
  }
  function getMaxOwners(WalletMainLib.WalletData storage self) public view returns (uint256) {
    return self.maxOwners;
  }
  function getOwnerCount(WalletMainLib.WalletData storage self) public view returns (uint256) {
    return self.owners.length - 1;
  }
  function getRequiredAdmin(WalletMainLib.WalletData storage self) public view returns (uint256) {
    return self.requiredAdmin;
  }
  function getRequiredMinor(WalletMainLib.WalletData storage self) public view returns (uint256) {
    return self.requiredMinor;
  }
  function getRequiredMajor(WalletMainLib.WalletData storage self) public view returns (uint256) {
    return self.requiredMajor;
  }
  function getCurrentSpend(WalletMainLib.WalletData storage self, address _token) public view returns (uint256[2]) {
    uint256[2] memory cs;
    cs[0] = self.currentSpend[_token][0];
    cs[1] = self.currentSpend[_token][1];
    return cs;
  }
  function getMajorThreshold(WalletMainLib.WalletData storage self, address _token) public view returns (uint256) {
    return self.majorThreshold[_token];
  }
  function getTransactionLength(WalletMainLib.WalletData storage self, bytes32 _id) public view returns (uint256) {
    return self.transactionInfo[_id].length;
  }
  function getTransactionConfirms(WalletMainLib.WalletData storage self,
                                  bytes32 _id,
                                  uint256 _txIndex)
                                  public view returns (uint256[50])
  {
    uint256[50] memory tc;
    for(uint256 i = 0; i<self.transactionInfo[_id][_txIndex].confirmedOwners.length; i++){
      tc[i] = self.transactionInfo[_id][_txIndex].confirmedOwners[i];
    }
    return tc;
  }
  function getTransactionConfirmCount(WalletMainLib.WalletData storage self,
                           bytes32 _id,
                           uint256 _txIndex)
                           public view returns(uint256)
  {
    return self.transactionInfo[_id][_txIndex].confirmCount;
  }
  function getTransactionSuccess(WalletMainLib.WalletData storage self,
                                 bytes32 _id,
                                 uint256 _txIndex)
                                 public view returns (bool)
  {
    return self.transactionInfo[_id][_txIndex].success;
  }
}