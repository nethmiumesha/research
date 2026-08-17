pragma solidity ^0.8.22;
library DynamicBuffer {
    function allocate(uint256 capacity_)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            let container := mload(0x40)
            {
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }
            {
                let length := add(capacity_, 0x40)
                mstore(container, length)
            }
            buffer := add(container, 0x20)
            mstore(buffer, 0)
        }
        return buffer;
    }
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                mstore(copyTo, mload(data))
            }
            mstore(buffer, add(mload(buffer), length))
        }
    }
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;
        if (data.length == 0) {
            return;
        }
        uint256 encodedLength;
        uint256 r;
        assembly {
            encodedLength := shl(2, div(add(dataLength, 2), 3))
            r := mod(dataLength, 3)
            if noPadding {
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }
        checkOverflow(buffer, encodedLength);
        assembly {
            let nextFree := mload(0x40)
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    mul(iszero(fileSafe), 0x0230)
                )
            )
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)
            for {} 1 {} {
                    data := add(data, 3)
                    let input := mload(data)
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    ptr := add(ptr, 4)
                    if iszero(lt(data, end)) { break }
                }
            if iszero(noPadding) {
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d)
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d)
            }
            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }
    function appendUncheckedBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;
        if (data.length == 0) {
            return;
        }
        uint256 encodedLength;
        uint256 r;
        assembly {
            encodedLength := shl(2, div(add(dataLength, 2), 3))
            r := mod(dataLength, 3)
            if noPadding {
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }
        assembly {
            let nextFree := mload(0x40)
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    mul(iszero(fileSafe), 0x0230)
                )
            )
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)
            for {} 1 {} {
                    data := add(data, 3)
                    let input := mload(data)
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    ptr := add(ptr, 4)
                    if iszero(lt(data, end)) { break }
                }
            if iszero(noPadding) {
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d)
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d)
            }
            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }
    function checkOverflow(bytes memory buffer, uint256 addedLength)
        internal
        pure
    {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}