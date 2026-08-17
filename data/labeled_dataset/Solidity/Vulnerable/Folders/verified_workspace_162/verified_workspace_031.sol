pragma solidity ^0.8.24;
import "src/shared/based/LibSharedData.sol";
interface ITaikoInbox {
    struct BlockParams {
        uint16 numTransactions;
        uint8 timeShift;
        bytes32[] signalSlots;
    }
    struct BlobParams {
        bytes32[] blobHashes;
        uint8 firstBlobIndex;
        uint8 numBlobs;
        uint32 byteOffset;
        uint32 byteSize;
        uint64 createdIn;
    }
    struct BatchParams {
        address proposer;
        address coinbase;
        bytes32 parentMetaHash;
        uint64 anchorBlockId;
        uint64 lastBlockTimestamp;
        bool revertIfNotFirstProposal;
        BlobParams blobParams;
        BlockParams[] blocks;
    }
    struct BatchInfo {
        bytes32 txsHash;
        BlockParams[] blocks;
        bytes32[] blobHashes;
        bytes32 extraData;
        address coinbase;
        uint64 proposedIn;
        uint64 blobCreatedIn;
        uint32 blobByteOffset;
        uint32 blobByteSize;
        uint32 gasLimit;
        uint64 lastBlockId;
        uint64 lastBlockTimestamp;
        uint64 anchorBlockId;
        bytes32 anchorBlockHash;
        LibSharedData.BaseFeeConfig baseFeeConfig;
    }
    struct BatchMetadata {
        bytes32 infoHash;
        address proposer;
        uint64 batchId;
        uint64 proposedAt;
    }
    struct Transition {
        bytes32 parentHash;
        bytes32 blockHash;
        bytes32 stateRoot;
    }
    struct TransitionState {
        bytes32 parentHash;
        bytes32 blockHash;
        bytes32 stateRoot;
        address prover;
        bool inProvingWindow;
        uint48 createdAt;
    }
    struct Batch {
        bytes32 metaHash;
        uint64 lastBlockId;
        uint96 reserved3;
        uint96 livenessBond;
        uint64 batchId;
        uint64 lastBlockTimestamp;
        uint64 anchorBlockId;
        uint24 nextTransitionId;
        uint8 reserved4;
        uint24 verifiedTransitionId;
    }
    struct Stats1 {
        uint64 genesisHeight;
        uint64 __reserved2;
        uint64 lastSyncedBatchId;
        uint64 lastSyncedAt;
    }
    struct Stats2 {
        uint64 numBatches;
        uint64 lastVerifiedBatchId;
        bool paused;
        uint56 lastProposedIn;
        uint64 lastUnpausedAt;
    }
    struct ForkHeights {
        uint64 ontake;
        uint64 pacaya;
        uint64 shasta;
        uint64 unzen;
    }
    struct Config {
        uint64 chainId;
        uint64 maxUnverifiedBatches;
        uint64 batchRingBufferSize;
        uint64 maxBatchesToVerify;
        uint32 blockMaxGasLimit;
        uint96 livenessBondBase;
        uint96 livenessBondPerBlock;
        uint8 stateRootSyncInternal;
        uint64 maxAnchorHeightOffset;
        LibSharedData.BaseFeeConfig baseFeeConfig;
        uint16 provingWindow;
        uint24 cooldownWindow;
        uint8 maxSignalsToReceive;
        uint16 maxBlocksPerBatch;
        ForkHeights forkHeights;
    }
    struct State {
        mapping(uint256 batchId_mod_batchRingBufferSize => Batch batch) batches;
        mapping(uint256 batchId => mapping(bytes32 parentHash => uint24 transitionId)) transitionIds;
        mapping(
            uint256 batchId_mod_batchRingBufferSize
                => mapping(uint24 transitionId => TransitionState ts)
        ) transitions;
        bytes32 __reserve1;
        Stats1 stats1;
        Stats2 stats2;
        mapping(address account => uint256 bond) bondBalance;
        uint256[43] __gap;
    }
    event BondDeposited(address indexed user, uint256 amount);
    event BondWithdrawn(address indexed user, uint256 amount);
    event BondCredited(address indexed user, uint256 amount);
    event BondDebited(address indexed user, uint256 amount);
    event Stats1Updated(Stats1 stats1);
    event Stats2Updated(Stats2 stats2);
    event BatchProposed(BatchInfo info, BatchMetadata meta, bytes txList);
    event BatchesProved(address verifier, uint64[] batchIds, Transition[] transitions);
    event ConflictingProof(uint64 batchId, TransitionState oldTran, Transition newTran);
    event BatchesVerified(uint64 batchId, bytes32 blockHash);
    error AnchorBlockIdSmallerThanParent();
    error AnchorBlockIdTooLarge();
    error AnchorBlockIdTooSmall();
    error ArraySizesMismatch();
    error BatchNotFound();
    error BatchVerified();
    error BeyondCurrentFork();
    error BlobNotFound();
    error BlockNotFound();
    error BlobNotSpecified();
    error ContractPaused();
    error CustomProposerMissing();
    error CustomProposerNotAllowed();
    error EtherNotPaidAsBond();
    error FirstBlockTimeShiftNotZero();
    error ForkNotActivated();
    error InsufficientBond();
    error InvalidBlobCreatedIn();
    error InvalidBlobParams();
    error InvalidGenesisBlockHash();
    error InvalidParams();
    error InvalidTransitionBlockHash();
    error InvalidTransitionParentHash();
    error InvalidTransitionStateRoot();
    error MetaHashMismatch();
    error MsgValueNotZero();
    error NoBlocksToProve();
    error NotFirstProposal();
    error NotInboxWrapper();
    error ParentMetaHashMismatch();
    error SameTransition();
    error SignalNotSent();
    error TimestampSmallerThanParent();
    error TimestampTooLarge();
    error TimestampTooSmall();
    error TooManyBatches();
    error TooManyBlocks();
    error TooManySignals();
    error TransitionNotFound();
    error ZeroAnchorBlockHash();
    function proposeBatch(
        bytes calldata _params,
        bytes calldata _txList
    )
        external
        returns (ITaikoInbox.BatchInfo memory info_, ITaikoInbox.BatchMetadata memory meta_);
    function proveBatches(bytes calldata _params, bytes calldata _proof) external;
    function depositBond(uint256 _amount) external payable;
    function withdrawBond(uint256 _amount) external;
    function bondBalanceOf(address _user) external view returns (uint256);
    function bondToken() external view returns (address);
    function getStats1() external view returns (Stats1 memory);
    function getStats2() external view returns (Stats2 memory);
    function getBatch(uint64 _batchId) external view returns (Batch memory batch_);
    function getTransitionById(
        uint64 _batchId,
        uint24 _tid
    )
        external
        view
        returns (ITaikoInbox.TransitionState memory);
    function getTransitionByParentHash(
        uint64 _batchId,
        bytes32 _parentHash
    )
        external
        view
        returns (ITaikoInbox.TransitionState memory);
    function getLastVerifiedTransition()
        external
        view
        returns (uint64 batchId_, uint64 blockId_, TransitionState memory ts_);
    function getLastSyncedTransition()
        external
        view
        returns (uint64 batchId_, uint64 blockId_, TransitionState memory ts_);
    function getBatchVerifyingTransition(uint64 _batchId)
        external
        view
        returns (TransitionState memory);
    function pacayaConfig() external view returns (Config memory);
}