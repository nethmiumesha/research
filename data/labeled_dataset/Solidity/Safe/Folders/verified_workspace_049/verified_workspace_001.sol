pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;
contract BlockhashRegistry {
    event LogBlockhashAdded(uint indexed blockNr, bytes32 indexed bhash);
    mapping(uint => bytes32) public blockhashMapping;
    constructor() public {
        snapshot();
    }
    function searchForAvailableBlock(uint _startNumber, uint _numBlocks) external view returns (uint) {
        for (uint i = _startNumber; i <= (_numBlocks + _startNumber); i++) {
            if (blockhashMapping[i] != 0x0) {
                return i;
            }
        }
    }
    function recreateBlockheaders(uint _blockNumber, bytes[] memory _blockheaders) public {
        bytes32 currentBlockhash = blockhashMapping[_blockNumber];
        require(currentBlockhash != 0x0, "parentBlock is not available");
        bytes32 calculatedHash = reCalculateBlockheaders(_blockheaders, currentBlockhash);
        require(calculatedHash != 0x0, "invalid headers");
        assert(_blockNumber > _blockheaders.length);
        uint bnr = _blockNumber - _blockheaders.length;
        blockhashMapping[bnr] = calculatedHash;
        emit LogBlockhashAdded(bnr, calculatedHash);
    }
    function saveBlockNumber(uint _blockNumber) public {
        bytes32 bHash = blockhash(_blockNumber);
        require(bHash != 0x0, "block not available");
        blockhashMapping[_blockNumber] = bHash;
        emit LogBlockhashAdded(_blockNumber, bHash);
    }
    function snapshot() public {
        saveBlockNumber(block.number-1);
    }
    function getParentAndBlockhash(bytes memory _blockheader) public pure returns (bytes32 parentHash, bytes32 bhash) {
        uint8 first = uint8(_blockheader[0]);
        require(first > 0xf7, "invalid offset");
        uint8 offset = first - 0xf7 + 2;
        assembly {
            mstore(0x20, _blockheader)
            parentHash :=mload(
                add(
                    add(
                        mload(0x20), 0x20
                    ), offset)
            )
        }
        bhash = keccak256(_blockheader);
    }
    function reCalculateBlockheaders(bytes[] memory _blockheaders, bytes32 _bHash) public pure returns (bytes32 bhash) {
        bytes32 currentBlockhash = _bHash;
        bytes32 calcParent = 0x0;
        bytes32 calcBlockhash = 0x0;
        for (uint i = 0; i < _blockheaders.length; i++) {
            (calcParent, calcBlockhash) = getParentAndBlockhash(_blockheaders[i]);
            if (calcBlockhash != currentBlockhash) {
                return 0x0;
            }
            currentBlockhash = calcParent;
        }
        return currentBlockhash;
    }
}