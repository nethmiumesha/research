pragma solidity ^0.8.24;
import "./ITaikoInbox.sol";
interface IProposeBatch {
    function proposeBatch(
        bytes calldata _params,
        bytes calldata _txList
    )
        external
        returns (ITaikoInbox.BatchInfo memory info_, ITaikoInbox.BatchMetadata memory meta_);
}