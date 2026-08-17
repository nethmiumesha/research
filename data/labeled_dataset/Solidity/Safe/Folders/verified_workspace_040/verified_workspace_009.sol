pragma solidity 0.5.11;
library TxPosLib {
    struct TxPos {
        uint256 value;
    }
    uint256 constant internal BLOCK_OFFSET_FOR_TX_POS = 1000000000 / 10000;
    function blockNum(TxPos memory _txPos)
        internal
        pure
        returns (uint256)
    {
        return _txPos.value / BLOCK_OFFSET_FOR_TX_POS;
    }
    function txIndex(TxPos memory _txPos)
        internal
        pure
        returns (uint256)
    {
        return _txPos.value % BLOCK_OFFSET_FOR_TX_POS;
    }
}