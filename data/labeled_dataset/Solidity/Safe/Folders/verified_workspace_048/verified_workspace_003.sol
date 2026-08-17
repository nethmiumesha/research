pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
contract TxnAggregator {
  struct ContractCall {
    address dest;
    bytes data;
  }
  event Error(uint256 tx_id, bytes error);
  function executeTxns(ContractCall[] calldata _txns, bool _revert) external {
    for (uint256 i = 0; i < _txns.length; i++) {
      (bool success, bytes memory resp) = _txns[i].dest.call(_txns[i].data);
      if (!success) {
        if (_revert) {
          revert(string(resp));
        } else {
          emit Error(i, resp);
        }
      }
    }
  }
  function singleContract_executeTxns(address _contract, bytes[] calldata _txns, bool _revert) external {
    for (uint256 i = 0; i < _txns.length; i++) {
      (bool success, bytes memory resp) = _contract.call(_txns[i]);
      if (!success) {
        if (_revert) {
          revert(string(resp));
        } else {
          emit Error(i, resp);
        }
      }
    }
  }
  function viewTxns(ContractCall[] calldata _txns) external view returns (bytes[] memory) {
    bool success;
    uint256 n_txns = _txns.length;
    bytes[] memory responses = new bytes[](n_txns);
    for (uint256 i = 0; i < n_txns; i++) {
      (success, responses[i]) = _txns[i].dest.staticcall(_txns[i].data);
    }
  }
}