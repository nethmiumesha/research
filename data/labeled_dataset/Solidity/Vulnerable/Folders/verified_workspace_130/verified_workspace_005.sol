pragma solidity ^0.8.4;
library LibBytes {
    struct BytesStorage {
        bytes32 _spacer;
    }
    uint256 internal constant NOT_FOUND = type(uint256).max;
    function set(BytesStorage storage $, bytes memory s) internal {
        assembly {
            let n := mload(s)
            let packed := or(0xff, shl(8, n))
            for { let i := 0 } 1 {} {
                if iszero(gt(n, 0xfe)) {
                    i := 0x1f
                    packed := or(n, shl(8, mload(add(s, i))))
                    if iszero(gt(n, i)) { break }
                }
                let o := add(s, 0x20)
                mstore(0x00, $.slot)
                for { let p := keccak256(0x00, 0x20) } 1 {} {
                    sstore(add(p, shr(5, i)), mload(add(o, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, n)) { break }
                }
                break
            }
            sstore($.slot, packed)
        }
    }
    function setCalldata(BytesStorage storage $, bytes calldata s) internal {
        assembly {
            let packed := or(0xff, shl(8, s.length))
            for { let i := 0 } 1 {} {
                if iszero(gt(s.length, 0xfe)) {
                    i := 0x1f
                    packed := or(s.length, shl(8, shr(8, calldataload(s.offset))))
                    if iszero(gt(s.length, i)) { break }
                }
                mstore(0x00, $.slot)
                for { let p := keccak256(0x00, 0x20) } 1 {} {
                    sstore(add(p, shr(5, i)), calldataload(add(s.offset, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, s.length)) { break }
                }
                break
            }
            sstore($.slot, packed)
        }
    }
    function clear(BytesStorage storage $) internal {
        delete $._spacer;
    }
    function isEmpty(BytesStorage storage $) internal view returns (bool) {
        return uint256($._spacer) & 0xff == uint256(0);
    }
    function length(BytesStorage storage $) internal view returns (uint256 result) {
        result = uint256($._spacer);
        assembly {
            let n := and(0xff, result)
            result := or(mul(shr(8, result), eq(0xff, n)), mul(n, iszero(eq(0xff, n))))
        }
    }
    function get(BytesStorage storage $) internal view returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            let o := add(result, 0x20)
            let packed := sload($.slot)
            let n := shr(8, packed)
            for { let i := 0 } 1 {} {
                if iszero(eq(or(packed, 0xff), packed)) {
                    mstore(o, packed)
                    n := and(0xff, packed)
                    i := 0x1f
                    if iszero(gt(n, i)) { break }
                }
                mstore(0x00, $.slot)
                for { let p := keccak256(0x00, 0x20) } 1 {} {
                    mstore(add(o, i), sload(add(p, shr(5, i))))
                    i := add(i, 0x20)
                    if iszero(lt(i, n)) { break }
                }
                break
            }
            mstore(result, n)
            mstore(add(o, n), 0)
            mstore(0x40, add(add(o, n), 0x20))
        }
    }
    function uint8At(BytesStorage storage $, uint256 i) internal view returns (uint8 result) {
        assembly {
            for { let packed := sload($.slot) } 1 {} {
                if iszero(eq(or(packed, 0xff), packed)) {
                    if iszero(gt(i, 0x1e)) {
                        result := byte(i, packed)
                        break
                    }
                    if iszero(gt(i, and(0xff, packed))) {
                        mstore(0x00, $.slot)
                        let j := sub(i, 0x1f)
                        result := byte(and(j, 0x1f), sload(add(keccak256(0x00, 0x20), shr(5, j))))
                    }
                    break
                }
                if iszero(gt(i, shr(8, packed))) {
                    mstore(0x00, $.slot)
                    result := byte(and(i, 0x1f), sload(add(keccak256(0x00, 0x20), shr(5, i))))
                }
                break
            }
        }
    }
    function replace(bytes memory subject, bytes memory needle, bytes memory replacement)
        internal
        pure
        returns (bytes memory result)
    {
        assembly {
            result := mload(0x40)
            let needleLen := mload(needle)
            let replacementLen := mload(replacement)
            let d := sub(result, subject)
            let i := add(subject, 0x20)
            mstore(0x00, add(i, mload(subject)))
            if iszero(gt(needleLen, mload(subject))) {
                let subjectSearchEnd := add(sub(mload(0x00), needleLen), 1)
                let h := 0
                if iszero(lt(needleLen, 0x20)) { h := keccak256(add(needle, 0x20), needleLen) }
                let s := mload(add(needle, 0x20))
                for { let m := shl(3, sub(0x20, and(needleLen, 0x1f))) } 1 {} {
                    let t := mload(i)
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(i, needleLen), h)) {
                                mstore(add(i, d), t)
                                i := add(i, 1)
                                if iszero(lt(i, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        for { let j := 0 } 1 {} {
                            mstore(add(add(i, d), j), mload(add(add(replacement, 0x20), j)))
                            j := add(j, 0x20)
                            if iszero(lt(j, replacementLen)) { break }
                        }
                        d := sub(add(d, replacementLen), needleLen)
                        if needleLen {
                            i := add(i, needleLen)
                            if iszero(lt(i, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(add(i, d), t)
                    i := add(i, 1)
                    if iszero(lt(i, subjectSearchEnd)) { break }
                }
            }
            let end := mload(0x00)
            let n := add(sub(d, add(result, 0x20)), end)
            for {} lt(i, end) { i := add(i, 0x20) } { mstore(add(i, d), mload(i)) }
            let o := add(i, d)
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
            mstore(result, n)
        }
    }
    function indexOf(bytes memory subject, bytes memory needle, uint256 from)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := not(0)
            for { let subjectLen := mload(subject) } 1 {} {
                if iszero(mload(needle)) {
                    result := from
                    if iszero(gt(from, subjectLen)) { break }
                    result := subjectLen
                    break
                }
                let needleLen := mload(needle)
                let subjectStart := add(subject, 0x20)
                subject := add(subjectStart, from)
                let end := add(sub(add(subjectStart, subjectLen), needleLen), 1)
                let m := shl(3, sub(0x20, and(needleLen, 0x1f)))
                let s := mload(add(needle, 0x20))
                if iszero(and(lt(subject, end), lt(from, subjectLen))) { break }
                if iszero(lt(needleLen, 0x20)) {
                    for { let h := keccak256(add(needle, 0x20), needleLen) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, needleLen), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        if iszero(lt(subject, end)) { break }
                    }
                    break
                }
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    if iszero(lt(subject, end)) { break }
                }
                break
            }
        }
    }
    function indexOfByte(bytes memory subject, bytes1 needle, uint256 from)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := not(0)
            if gt(mload(subject), from) {
                let start := add(subject, 0x20)
                let end := add(start, mload(subject))
                let m := div(not(0), 255)
                let h := mul(byte(0, needle), m)
                m := not(shl(7, m))
                for { let i := add(start, from) } 1 {} {
                    let c := xor(mload(i), h)
                    c := not(or(or(add(and(c, m), m), c), m))
                    if c {
                        c := and(not(shr(shl(3, sub(end, i)), not(0))), c)
                        if c {
                            let r := shl(7, lt(0x8421084210842108cc6318c6db6d54be, c))
                            r := or(shl(6, lt(0xffffffffffffffff, shr(r, c))), r)
                            result := add(sub(i, start), shr(3, xor(byte(and(0x1f, shr(byte(24,
                                mul(0x02040810204081, shr(r, c))), 0x8421084210842108cc6318c6db6d54be)),
                                0xc0c8c8d0c8e8d0d8c8e8e0e8d0d8e0f0c8d0e8d0e0e0d8f0d0d0e0d8f8f8f8f8), r)))
                            break
                        }
                    }
                    i := add(i, 0x20)
                    if iszero(lt(i, end)) { break }
                }
            }
        }
    }
    function indexOfByte(bytes memory subject, bytes1 needle)
        internal
        pure
        returns (uint256 result)
    {
        return indexOfByte(subject, needle, 0);
    }
    function indexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256) {
        return indexOf(subject, needle, 0);
    }
    function lastIndexOf(bytes memory subject, bytes memory needle, uint256 from)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            for {} 1 {} {
                result := not(0)
                let needleLen := mload(needle)
                if gt(needleLen, mload(subject)) { break }
                let w := result
                let fromMax := sub(mload(subject), needleLen)
                if iszero(gt(fromMax, from)) { from := fromMax }
                let end := add(add(subject, 0x20), w)
                subject := add(add(subject, 0x20), from)
                if iszero(gt(subject, end)) { break }
                for { let h := keccak256(add(needle, 0x20), needleLen) } 1 {} {
                    if eq(keccak256(subject, needleLen), h) {
                        result := sub(subject, add(end, 1))
                        break
                    }
                    subject := add(subject, w)
                    if iszero(gt(subject, end)) { break }
                }
                break
            }
        }
    }
    function lastIndexOf(bytes memory subject, bytes memory needle)
        internal
        pure
        returns (uint256)
    {
        return lastIndexOf(subject, needle, type(uint256).max);
    }
    function contains(bytes memory subject, bytes memory needle) internal pure returns (bool) {
        return indexOf(subject, needle) != NOT_FOUND;
    }
    function startsWith(bytes memory subject, bytes memory needle)
        internal
        pure
        returns (bool result)
    {
        assembly {
            let n := mload(needle)
            let t := eq(keccak256(add(subject, 0x20), n), keccak256(add(needle, 0x20), n))
            result := lt(gt(n, mload(subject)), t)
        }
    }
    function endsWith(bytes memory subject, bytes memory needle)
        internal
        pure
        returns (bool result)
    {
        assembly {
            let n := mload(needle)
            let notInRange := gt(n, mload(subject))
            let t := add(add(subject, 0x20), mul(iszero(notInRange), sub(mload(subject), n)))
            result := gt(eq(keccak256(t, n), keccak256(add(needle, 0x20), n)), notInRange)
        }
    }
    function repeat(bytes memory subject, uint256 times)
        internal
        pure
        returns (bytes memory result)
    {
        assembly {
            let l := mload(subject)
            if iszero(or(iszero(times), iszero(l))) {
                result := mload(0x40)
                subject := add(subject, 0x20)
                let o := add(result, 0x20)
                for {} 1 {} {
                    for { let j := 0 } 1 {} {
                        mstore(add(o, j), mload(add(subject, j)))
                        j := add(j, 0x20)
                        if iszero(lt(j, l)) { break }
                    }
                    o := add(o, l)
                    times := sub(times, 1)
                    if iszero(times) { break }
                }
                mstore(o, 0)
                mstore(0x40, add(o, 0x20))
                mstore(result, sub(o, add(result, 0x20)))
            }
        }
    }
    function slice(bytes memory subject, uint256 start, uint256 end)
        internal
        pure
        returns (bytes memory result)
    {
        assembly {
            let l := mload(subject)
            if iszero(gt(l, end)) { end := l }
            if iszero(gt(l, start)) { start := l }
            if lt(start, end) {
                result := mload(0x40)
                let n := sub(end, start)
                let i := add(subject, start)
                let w := not(0x1f)
                for { let j := and(add(n, 0x1f), w) } 1 {} {
                    mstore(add(result, j), mload(add(i, j)))
                    j := add(j, w)
                    if iszero(j) { break }
                }
                let o := add(add(result, 0x20), n)
                mstore(o, 0)
                mstore(0x40, add(o, 0x20))
                mstore(result, n)
            }
        }
    }
    function slice(bytes memory subject, uint256 start)
        internal
        pure
        returns (bytes memory result)
    {
        result = slice(subject, start, type(uint256).max);
    }
    function sliceCalldata(bytes calldata subject, uint256 start, uint256 end)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            end := xor(end, mul(xor(end, subject.length), lt(subject.length, end)))
            start := xor(start, mul(xor(start, subject.length), lt(subject.length, start)))
            result.offset := add(subject.offset, start)
            result.length := mul(lt(start, end), sub(end, start))
        }
    }
    function sliceCalldata(bytes calldata subject, uint256 start)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            start := xor(start, mul(xor(start, subject.length), lt(subject.length, start)))
            result.offset := add(subject.offset, start)
            result.length := mul(lt(start, subject.length), sub(subject.length, start))
        }
    }
    function truncate(bytes memory subject, uint256 n)
        internal
        pure
        returns (bytes memory result)
    {
        assembly {
            result := subject
            mstore(mul(lt(n, mload(result)), result), n)
        }
    }
    function truncatedCalldata(bytes calldata subject, uint256 n)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := subject.offset
            result.length := xor(n, mul(xor(n, subject.length), lt(subject.length, n)))
        }
    }
    function indicesOf(bytes memory subject, bytes memory needle)
        internal
        pure
        returns (uint256[] memory result)
    {
        assembly {
            let searchLen := mload(needle)
            if iszero(gt(searchLen, mload(subject))) {
                result := mload(0x40)
                let i := add(subject, 0x20)
                let o := add(result, 0x20)
                let subjectSearchEnd := add(sub(add(i, mload(subject)), searchLen), 1)
                let h := 0
                if iszero(lt(searchLen, 0x20)) { h := keccak256(add(needle, 0x20), searchLen) }
                let s := mload(add(needle, 0x20))
                for { let m := shl(3, sub(0x20, and(searchLen, 0x1f))) } 1 {} {
                    let t := mload(i)
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(i, searchLen), h)) {
                                i := add(i, 1)
                                if iszero(lt(i, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        mstore(o, sub(i, add(subject, 0x20)))
                        o := add(o, 0x20)
                        i := add(i, searchLen)
                        if searchLen {
                            if iszero(lt(i, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    i := add(i, 1)
                    if iszero(lt(i, subjectSearchEnd)) { break }
                }
                mstore(result, shr(5, sub(o, add(result, 0x20))))
                mstore(0x40, add(o, 0x20))
            }
        }
    }
    function split(bytes memory subject, bytes memory delimiter)
        internal
        pure
        returns (bytes[] memory result)
    {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            let w := not(0x1f)
            let indexPtr := add(indices, 0x20)
            let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
            mstore(add(indicesEnd, w), mload(subject))
            mstore(indices, add(mload(indices), 1))
            for { let prevIndex := 0 } 1 {} {
                let index := mload(indexPtr)
                mstore(indexPtr, 0x60)
                if iszero(eq(index, prevIndex)) {
                    let element := mload(0x40)
                    let l := sub(index, prevIndex)
                    mstore(element, l)
                    for { let o := and(add(l, 0x1f), w) } 1 {} {
                        mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                        o := add(o, w)
                        if iszero(o) { break }
                    }
                    mstore(add(add(element, 0x20), l), 0)
                    mstore(0x40, add(element, and(add(l, 0x3f), w)))
                    mstore(indexPtr, element)
                }
                prevIndex := add(index, mload(delimiter))
                indexPtr := add(indexPtr, 0x20)
                if iszero(lt(indexPtr, indicesEnd)) { break }
            }
            result := indices
            if iszero(mload(delimiter)) {
                result := add(indices, 0x20)
                mstore(result, sub(mload(indices), 2))
            }
        }
    }
    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            let w := not(0x1f)
            let aLen := mload(a)
            for { let o := and(add(aLen, 0x20), w) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            let bLen := mload(b)
            let output := add(result, aLen)
            for { let o := and(add(bLen, 0x20), w) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            let totalLen := add(aLen, bLen)
            let last := add(add(result, 0x20), totalLen)
            mstore(last, 0)
            mstore(result, totalLen)
            mstore(0x40, add(last, 0x20))
        }
    }
    function eq(bytes memory a, bytes memory b) internal pure returns (bool result) {
        assembly {
            result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
        }
    }
    function eqs(bytes memory a, bytes32 b) internal pure returns (bool result) {
        assembly {
            let m := not(shl(7, div(not(iszero(b)), 255)))
            let x := not(or(m, or(b, add(m, and(b, m)))))
            let r := shl(7, iszero(iszero(shr(128, x))))
            r := or(r, shl(6, iszero(iszero(shr(64, shr(r, x))))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            result := gt(eq(mload(a), add(iszero(x), xor(31, shr(3, r)))),
                xor(shr(add(8, r), b), shr(add(8, r), mload(add(a, 0x20)))))
        }
    }
    function cmp(bytes memory a, bytes memory b) internal pure returns (int256 result) {
        assembly {
            let aLen := mload(a)
            let bLen := mload(b)
            let n := and(xor(aLen, mul(xor(aLen, bLen), lt(bLen, aLen))), not(0x1f))
            if n {
                for { let i := 0x20 } 1 {} {
                    let x := mload(add(a, i))
                    let y := mload(add(b, i))
                    if iszero(or(xor(x, y), eq(i, n))) {
                        i := add(i, 0x20)
                        continue
                    }
                    result := sub(gt(x, y), lt(x, y))
                    break
                }
            }
            if iszero(result) {
                let l := 0x201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201
                let x := and(mload(add(add(a, 0x20), n)), shl(shl(3, byte(sub(aLen, n), l)), not(0)))
                let y := and(mload(add(add(b, 0x20), n)), shl(shl(3, byte(sub(bLen, n), l)), not(0)))
                result := sub(gt(x, y), lt(x, y))
                if iszero(result) { result := sub(gt(aLen, bLen), lt(aLen, bLen)) }
            }
        }
    }
    function directReturn(bytes memory a) internal pure {
        assembly {
            let retStart := sub(a, 0x20)
            let retUnpaddedSize := add(mload(a), 0x40)
            mstore(add(retStart, retUnpaddedSize), 0)
            mstore(retStart, 0x20)
            return(retStart, and(not(0x1f), add(0x1f, retUnpaddedSize)))
        }
    }
    function directReturn(bytes[] memory a) internal pure {
        assembly {
            let n := mload(a)
            let o := add(a, 0x20)
            let u := a
            let w := not(0x1f)
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                let c := add(o, shl(5, i))
                let s := mload(c)
                let l := mload(s)
                let r := and(l, 0x1f)
                let z := add(0x20, and(l, w))
                if iszero(lt(lt(s, o), or(iszero(r), iszero(shl(shl(3, r), mload(add(s, z))))))) {
                    let m := mload(0x40)
                    mstore(m, l)
                    for {} 1 {} {
                        mstore(add(m, z), mload(add(s, z)))
                        z := add(z, w)
                        if iszero(z) { break }
                    }
                    let e := add(add(m, 0x20), l)
                    mstore(e, 0)
                    mstore(0x40, add(e, 0x20))
                    s := m
                }
                mstore(c, sub(s, o))
                let t := add(l, add(s, 0x20))
                if iszero(lt(t, u)) { u := t }
            }
            let retStart := add(a, w)
            mstore(retStart, 0x20)
            return(retStart, add(0x40, sub(u, retStart)))
        }
    }
    function load(bytes memory a, uint256 offset) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(a, 0x20), offset))
        }
    }
    function loadCalldata(bytes calldata a, uint256 offset)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            result := calldataload(add(a.offset, offset))
        }
    }
    function staticStructInCalldata(bytes calldata a, uint256 offset)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            let l := sub(a.length, 0x20)
            result.offset := add(a.offset, offset)
            result.length := sub(a.length, offset)
            if or(shr(64, or(l, a.offset)), gt(offset, l)) { revert(l, 0x00) }
        }
    }
    function dynamicStructInCalldata(bytes calldata a, uint256 offset)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            let l := sub(a.length, 0x20)
            let s := calldataload(add(a.offset, offset))
            result.offset := add(a.offset, s)
            result.length := sub(a.length, s)
            if or(shr(64, or(s, or(l, a.offset))), gt(offset, l)) { revert(l, 0x00) }
        }
    }
    function bytesInCalldata(bytes calldata a, uint256 offset)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            let l := sub(a.length, 0x20)
            let s := calldataload(add(a.offset, offset))
            result.offset := add(add(a.offset, s), 0x20)
            result.length := calldataload(add(a.offset, s))
            if or(shr(64, or(result.length, or(s, or(l, a.offset)))),
                or(gt(add(s, result.length), l), gt(offset, l))) { revert(l, 0x00) }
        }
    }
    function checkInCalldata(bytes calldata x, bytes calldata a) internal pure {
        assembly {
            if or(
                or(lt(x.offset, a.offset), gt(add(x.offset, x.length), add(a.length, a.offset))),
                shr(64, or(x.length, x.offset))
            ) { revert(0x00, 0x00) }
        }
    }
    function checkInCalldata(bytes[] calldata x, bytes calldata a) internal pure {
        assembly {
            let e := sub(add(a.length, a.offset), 0x20)
            if or(lt(x.offset, a.offset), shr(64, x.offset)) { revert(0x00, 0x00) }
            for { let i := 0 } iszero(eq(x.length, i)) { i := add(i, 1) } {
                let o := calldataload(add(x.offset, shl(5, i)))
                let t := add(o, x.offset)
                let l := calldataload(t)
                if or(shr(64, or(l, o)), gt(add(t, l), e)) { revert(0x00, 0x00) }
            }
        }
    }
    function emptyCalldata() internal pure returns (bytes calldata result) {
        assembly {
            result.length := 0
        }
    }
    function msbToAddress(bytes32 x) internal pure returns (address) {
        return address(bytes20(x));
    }
    function lsbToAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }
}