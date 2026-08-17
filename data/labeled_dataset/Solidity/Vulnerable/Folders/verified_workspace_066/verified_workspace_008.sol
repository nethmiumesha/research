pragma solidity >0.5.0 <0.8.0;
library Lib_RingBuffer {
    using Lib_RingBuffer for RingBuffer;
    struct Buffer {
        uint256 length;
        mapping (uint256 => bytes32) buf;
    }
    struct RingBuffer {
        bytes32 contextA;
        bytes32 contextB;
        Buffer bufferA;
        Buffer bufferB;
        uint256 nextOverwritableIndex;
    }
    struct RingBufferContext {
        uint40 globalIndex;
        bytes27 extraData;
        uint64 currBufferIndex;
        uint40 prevResetIndex;
        uint40 currResetIndex;
    }
    uint256 constant MIN_CAPACITY = 16;
    function push(
        RingBuffer storage _self,
        bytes32 _value,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        Buffer storage currBuffer = _self.getBuffer(ctx.currBufferIndex);
        if (currBuffer.length == 0) {
            currBuffer.length = MIN_CAPACITY;
        }
        if (ctx.globalIndex - ctx.currResetIndex >= currBuffer.length) {
            if (ctx.currResetIndex < _self.nextOverwritableIndex) {
                ctx.currBufferIndex++;
                ctx.prevResetIndex = ctx.currResetIndex;
                ctx.currResetIndex = ctx.globalIndex;
                currBuffer = _self.getBuffer(ctx.currBufferIndex);
            } else {
                currBuffer.length *= 2;
            }
        }
        uint256 writeHead = ctx.globalIndex - ctx.currResetIndex;
        currBuffer.buf[writeHead] = _value;
        ctx.globalIndex++;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }
    function push(
        RingBuffer storage _self,
        bytes32 _value
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        _self.push(
            _value,
            ctx.extraData
        );
    }
    function get(
        RingBuffer storage _self,
        uint256 _index
    )
        internal
        view
        returns (
            bytes32
        )
    {
        RingBufferContext memory ctx = _self.getContext();
        require(
            _index < ctx.globalIndex,
            "Index out of bounds."
        );
        Buffer storage currBuffer = _self.getBuffer(ctx.currBufferIndex);
        Buffer storage prevBuffer = _self.getBuffer(ctx.currBufferIndex + 1);
        if (_index >= ctx.currResetIndex) {
            uint256 relativeIndex = _index - ctx.currResetIndex;
            require(
                relativeIndex < currBuffer.length,
                "Index out of bounds."
            );
            return currBuffer.buf[relativeIndex];
        } else {
            uint256 relativeIndex = ctx.currResetIndex - _index;
            require(
                ctx.currResetIndex > ctx.prevResetIndex,
                "Index out of bounds."
            );
            require(
                relativeIndex <= prevBuffer.length,
                "Index out of bounds."
            );
            return prevBuffer.buf[prevBuffer.length - relativeIndex];
        }
    }
    function deleteElementsAfterInclusive(
        RingBuffer storage _self,
        uint40 _index,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        require(
            _index < ctx.globalIndex && _index >= ctx.prevResetIndex,
            "Index out of bounds."
        );
        if (_index < ctx.currResetIndex) {
            ctx.currBufferIndex--;
            ctx.currResetIndex = ctx.prevResetIndex;
        }
        ctx.globalIndex = _index;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }
    function deleteElementsAfterInclusive(
        RingBuffer storage _self,
        uint40 _index
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        _self.deleteElementsAfterInclusive(
            _index,
            ctx.extraData
        );
    }
    function getLength(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            uint40
        )
    {
        RingBufferContext memory ctx = _self.getContext();
        return ctx.globalIndex;
    }
    function setExtraData(
        RingBuffer storage _self,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }
    function getExtraData(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            bytes27
        )
    {
        RingBufferContext memory ctx = _self.getContext();
        return ctx.extraData;
    }
    function setContext(
        RingBuffer storage _self,
        RingBufferContext memory _ctx
    )
        internal
    {
        bytes32 contextA;
        bytes32 contextB;
        uint40 globalIndex = _ctx.globalIndex;
        bytes27 extraData = _ctx.extraData;
        assembly {
            contextA := globalIndex
            contextA := or(contextA, extraData)
        }
        uint64 currBufferIndex = _ctx.currBufferIndex;
        uint40 prevResetIndex = _ctx.prevResetIndex;
        uint40 currResetIndex = _ctx.currResetIndex;
        assembly {
            contextB := currBufferIndex
            contextB := or(contextB, shl(64, prevResetIndex))
            contextB := or(contextB, shl(104, currResetIndex))
        }
        if (_self.contextA != contextA) {
            _self.contextA = contextA;
        }
        if (_self.contextB != contextB) {
            _self.contextB = contextB;
        }
    }
    function getContext(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            RingBufferContext memory
        )
    {
        bytes32 contextA = _self.contextA;
        bytes32 contextB = _self.contextB;
        uint40 globalIndex;
        bytes27 extraData;
        assembly {
            globalIndex := and(contextA, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            extraData   := and(contextA, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000)
        }
        uint64 currBufferIndex;
        uint40 prevResetIndex;
        uint40 currResetIndex;
        assembly {
            currBufferIndex :=          and(contextB, 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF)
            prevResetIndex  := shr(64,  and(contextB, 0x00000000000000000000000000000000000000FFFFFFFFFF0000000000000000))
            currResetIndex  := shr(104, and(contextB, 0x0000000000000000000000000000FFFFFFFFFF00000000000000000000000000))
        }
        return RingBufferContext({
            globalIndex: globalIndex,
            extraData: extraData,
            currBufferIndex: currBufferIndex,
            prevResetIndex: prevResetIndex,
            currResetIndex: currResetIndex
        });
    }
    function getBuffer(
        RingBuffer storage _self,
        uint256 _which
    )
        internal
        view
        returns (
            Buffer storage
        )
    {
        return _which % 2 == 0 ? _self.bufferA : _self.bufferB;
    }
}