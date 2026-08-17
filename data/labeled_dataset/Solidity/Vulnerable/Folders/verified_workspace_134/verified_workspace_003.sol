pragma solidity ^0.8.22;
struct BytecodeSlice {
    address pointer;
    uint32 start;
    uint32 end;
}
struct File {
    uint256 size;
    BytecodeSlice[] slices;
}
using {read} for File global;
using {readUnchecked} for File global;
error SliceOutOfBounds(
    address pointer,
    uint32 codeSize,
    uint32 sliceStart,
    uint32 sliceEnd
);
function read(File memory file) view returns (string memory contents) {
    BytecodeSlice[] memory slices = file.slices;
    bytes4 sliceOutOfBoundsSelector = SliceOutOfBounds.selector;
    assembly {
        let len := mload(slices)
        let size := 0x20
        contents := mload(0x40)
        let slice
        let pointer
        let start
        let end
        let codeSize
        for {
            let i := 0
        } lt(i, len) {
            i := add(i, 1)
        } {
            slice := mload(add(slices, add(0x20, mul(i, 0x20))))
            pointer := mload(slice)
            start := mload(add(slice, 0x20))
            end := mload(add(slice, 0x40))
            codeSize := extcodesize(pointer)
            if gt(end, codeSize) {
                mstore(0x00, sliceOutOfBoundsSelector)
                mstore(0x04, pointer)
                mstore(0x24, codeSize)
                mstore(0x44, start)
                mstore(0x64, end)
                revert(0x00, 0x84)
            }
            extcodecopy(pointer, add(contents, size), start, sub(end, start))
            size := add(size, sub(end, start))
        }
        mstore(contents, sub(size, 0x20))
        mstore(0x40, add(contents, and(add(size, 0x1f), not(0x1f))))
    }
}
function readUnchecked(File memory file) view returns (string memory contents) {
    BytecodeSlice[] memory slices = file.slices;
    assembly {
        let len := mload(slices)
        let size := 0x20
        contents := mload(0x40)
        let slice
        let pointer
        let start
        let end
        let codeSize
        for {
            let i := 0
        } lt(i, len) {
            i := add(i, 1)
        } {
            slice := mload(add(slices, add(0x20, mul(i, 0x20))))
            pointer := mload(slice)
            start := mload(add(slice, 0x20))
            end := mload(add(slice, 0x40))
            codeSize := extcodesize(pointer)
            if lt(end, codeSize) {
                extcodecopy(
                    pointer,
                    add(contents, size),
                    start,
                    sub(end, start)
                )
                size := add(size, sub(end, start))
            }
        }
        mstore(contents, sub(size, 0x20))
        mstore(0x40, add(contents, and(add(size, 0x1f), not(0x1f))))
    }
}