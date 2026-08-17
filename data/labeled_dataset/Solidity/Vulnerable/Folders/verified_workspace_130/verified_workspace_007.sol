pragma solidity ^0.8.4;
import {LibBytes} from "./LibBytes.sol";
library LibString {
    struct StringStorage {
        bytes32 _spacer;
    }
    error HexLengthInsufficient();
    error TooBigForSmallString();
    error StringNot7BitASCII();
    uint256 internal constant NOT_FOUND = type(uint256).max;
    uint128 internal constant ALPHANUMERIC_7_BIT_ASCII = 0x7fffffe07fffffe03ff000000000000;
    uint128 internal constant LETTERS_7_BIT_ASCII = 0x7fffffe07fffffe0000000000000000;
    uint128 internal constant LOWERCASE_7_BIT_ASCII = 0x7fffffe000000000000000000000000;
    uint128 internal constant UPPERCASE_7_BIT_ASCII = 0x7fffffe0000000000000000;
    uint128 internal constant DIGITS_7_BIT_ASCII = 0x3ff000000000000;
    uint128 internal constant HEXDIGITS_7_BIT_ASCII = 0x7e0000007e03ff000000000000;
    uint128 internal constant OCTDIGITS_7_BIT_ASCII = 0xff000000000000;
    uint128 internal constant PRINTABLE_7_BIT_ASCII = 0x7fffffffffffffffffffffff00003e00;
    uint128 internal constant PUNCTUATION_7_BIT_ASCII = 0x78000001f8000001fc00fffe00000000;
    uint128 internal constant WHITESPACE_7_BIT_ASCII = 0x100003e00;
    function set(StringStorage storage $, string memory s) internal {
        LibBytes.set(bytesStorage($), bytes(s));
    }
    function setCalldata(StringStorage storage $, string calldata s) internal {
        LibBytes.setCalldata(bytesStorage($), bytes(s));
    }
    function clear(StringStorage storage $) internal {
        delete $._spacer;
    }
    function isEmpty(StringStorage storage $) internal view returns (bool) {
        return uint256($._spacer) & 0xff == uint256(0);
    }
    function length(StringStorage storage $) internal view returns (uint256) {
        return LibBytes.length(bytesStorage($));
    }
    function get(StringStorage storage $) internal view returns (string memory) {
        return string(LibBytes.get(bytesStorage($)));
    }
    function uint8At(StringStorage storage $, uint256 i) internal view returns (uint8) {
        return LibBytes.uint8At(bytesStorage($), i);
    }
    function bytesStorage(StringStorage storage $)
        internal
        pure
        returns (LibBytes.BytesStorage storage casted)
    {
        assembly {
            casted.slot := $.slot
        }
    }
    function toString(uint256 value) internal pure returns (string memory result) {
        assembly {
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20))
            mstore(result, 0)
            let end := result
            let w := not(0)
            for { let temp := value } 1 {} {
                result := add(result, w)
                mstore8(result, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n)
        }
    }
    function toString(int256 value) internal pure returns (string memory result) {
        if (value >= 0) return toString(uint256(value));
        unchecked {
            result = toString(~uint256(value) + 1);
        }
        assembly {
            let n := mload(result)
            mstore(result, 0x2d)
            result := sub(result, 1)
            mstore(result, add(n, 1))
        }
    }
    function toHexString(uint256 value, uint256 byteCount)
        internal
        pure
        returns (string memory result)
    {
        result = toHexStringNoPrefix(value, byteCount);
        assembly {
            let n := add(mload(result), 2)
            mstore(result, 0x3078)
            result := sub(result, 2)
            mstore(result, n)
        }
    }
    function toHexStringNoPrefix(uint256 value, uint256 byteCount)
        internal
        pure
        returns (string memory result)
    {
        assembly {
            result := add(mload(0x40), and(add(shl(1, byteCount), 0x42), not(0x1f)))
            mstore(0x40, add(result, 0x20))
            mstore(result, 0)
            let end := result
            mstore(0x0f, 0x30313233343536373839616263646566)
            let start := sub(result, add(byteCount, byteCount))
            let w := not(1)
            let temp := value
            for {} 1 {} {
                result := add(result, w)
                mstore8(add(result, 1), mload(and(temp, 15)))
                mstore8(result, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                if iszero(xor(result, start)) { break }
            }
            if temp {
                mstore(0x00, 0x2194895a)
                revert(0x1c, 0x04)
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n)
        }
    }
    function toHexString(uint256 value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        assembly {
            let n := add(mload(result), 2)
            mstore(result, 0x3078)
            result := sub(result, 2)
            mstore(result, n)
        }
    }
    function toMinimalHexString(uint256 value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        assembly {
            let o := eq(byte(0, mload(add(result, 0x20))), 0x30)
            let n := add(mload(result), 2)
            mstore(add(result, o), 0x3078)
            result := sub(add(result, o), 2)
            mstore(result, sub(n, o))
        }
    }
    function toMinimalHexStringNoPrefix(uint256 value)
        internal
        pure
        returns (string memory result)
    {
        result = toHexStringNoPrefix(value);
        assembly {
            let o := eq(byte(0, mload(add(result, 0x20))), 0x30)
            let n := mload(result)
            result := add(result, o)
            mstore(result, sub(n, o))
        }
    }
    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory result) {
        assembly {
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20))
            mstore(result, 0)
            let end := result
            mstore(0x0f, 0x30313233343536373839616263646566)
            let w := not(1)
            for { let temp := value } 1 {} {
                result := add(result, w)
                mstore8(add(result, 1), mload(and(temp, 15)))
                mstore8(result, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                if iszero(temp) { break }
            }
            let n := sub(end, result)
            result := sub(result, 0x20)
            mstore(result, n)
        }
    }
    function toHexStringChecksummed(address value) internal pure returns (string memory result) {
        result = toHexString(value);
        assembly {
            let mask := shl(6, div(not(0), 255))
            let o := add(result, 0x22)
            let hashed := and(keccak256(o, 40), mul(34, mask))
            let t := shl(240, 136)
            for { let i := 0 } 1 {} {
                mstore(add(i, i), mul(t, byte(i, hashed)))
                i := add(i, 1)
                if eq(i, 20) { break }
            }
            mstore(o, xor(mload(o), shr(1, and(mload(0x00), and(mload(o), mask)))))
            o := add(o, 0x20)
            mstore(o, xor(mload(o), shr(1, and(mload(0x20), and(mload(o), mask)))))
        }
    }
    function toHexString(address value) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(value);
        assembly {
            let n := add(mload(result), 2)
            mstore(result, 0x3078)
            result := sub(result, 2)
            mstore(result, n)
        }
    }
    function toHexStringNoPrefix(address value) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            mstore(0x40, add(result, 0x80))
            mstore(0x0f, 0x30313233343536373839616263646566)
            result := add(result, 2)
            mstore(result, 40)
            let o := add(result, 0x20)
            mstore(add(o, 40), 0)
            value := shl(96, value)
            for { let i := 0 } 1 {} {
                let p := add(o, add(i, i))
                let temp := byte(i, value)
                mstore8(add(p, 1), mload(and(temp, 15)))
                mstore8(p, mload(shr(4, temp)))
                i := add(i, 1)
                if eq(i, 20) { break }
            }
        }
    }
    function toHexString(bytes memory raw) internal pure returns (string memory result) {
        result = toHexStringNoPrefix(raw);
        assembly {
            let n := add(mload(result), 2)
            mstore(result, 0x3078)
            result := sub(result, 2)
            mstore(result, n)
        }
    }
    function toHexStringNoPrefix(bytes memory raw) internal pure returns (string memory result) {
        assembly {
            let n := mload(raw)
            result := add(mload(0x40), 2)
            mstore(result, add(n, n))
            mstore(0x0f, 0x30313233343536373839616263646566)
            let o := add(result, 0x20)
            let end := add(raw, n)
            for {} iszero(eq(raw, end)) {} {
                raw := add(raw, 1)
                mstore8(add(o, 1), mload(and(mload(raw), 15)))
                mstore8(o, mload(and(shr(4, mload(raw)), 15)))
                o := add(o, 2)
            }
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }
    function runeCount(string memory s) internal pure returns (uint256 result) {
        assembly {
            if mload(s) {
                mstore(0x00, div(not(0), 255))
                mstore(0x20, 0x0202020202020202020202020202020202020202020202020303030304040506)
                let o := add(s, 0x20)
                let end := add(o, mload(s))
                for { result := 1 } 1 { result := add(result, 1) } {
                    o := add(o, byte(0, mload(shr(250, mload(o)))))
                    if iszero(lt(o, end)) { break }
                }
            }
        }
    }
    function is7BitASCII(string memory s) internal pure returns (bool result) {
        assembly {
            result := 1
            let mask := shl(7, div(not(0), 255))
            let n := mload(s)
            if n {
                let o := add(s, 0x20)
                let end := add(o, n)
                let last := mload(end)
                mstore(end, 0)
                for {} 1 {} {
                    if and(mask, mload(o)) {
                        result := 0
                        break
                    }
                    o := add(o, 0x20)
                    if iszero(lt(o, end)) { break }
                }
                mstore(end, last)
            }
        }
    }
    function is7BitASCII(string memory s, uint128 allowed) internal pure returns (bool result) {
        assembly {
            result := 1
            if mload(s) {
                let allowed_ := shr(128, shl(128, allowed))
                let o := add(s, 0x20)
                for { let end := add(o, mload(s)) } 1 {} {
                    result := and(result, shr(byte(0, mload(o)), allowed_))
                    o := add(o, 1)
                    if iszero(and(result, lt(o, end))) { break }
                }
            }
        }
    }
    function to7BitASCIIAllowedLookup(string memory s) internal pure returns (uint128 result) {
        assembly {
            if mload(s) {
                let o := add(s, 0x20)
                for { let end := add(o, mload(s)) } 1 {} {
                    result := or(result, shl(byte(0, mload(o)), 1))
                    o := add(o, 1)
                    if iszero(lt(o, end)) { break }
                }
                if shr(128, result) {
                    mstore(0x00, 0xc9807e0d)
                    revert(0x1c, 0x04)
                }
            }
        }
    }
    function replace(string memory subject, string memory needle, string memory replacement)
        internal
        pure
        returns (string memory)
    {
        return string(LibBytes.replace(bytes(subject), bytes(needle), bytes(replacement)));
    }
    function indexOf(string memory subject, string memory needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return LibBytes.indexOf(bytes(subject), bytes(needle), from);
    }
    function indexOf(string memory subject, string memory needle) internal pure returns (uint256) {
        return LibBytes.indexOf(bytes(subject), bytes(needle), 0);
    }
    function lastIndexOf(string memory subject, string memory needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return LibBytes.lastIndexOf(bytes(subject), bytes(needle), from);
    }
    function lastIndexOf(string memory subject, string memory needle)
        internal
        pure
        returns (uint256)
    {
        return LibBytes.lastIndexOf(bytes(subject), bytes(needle), type(uint256).max);
    }
    function contains(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.contains(bytes(subject), bytes(needle));
    }
    function startsWith(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.startsWith(bytes(subject), bytes(needle));
    }
    function endsWith(string memory subject, string memory needle) internal pure returns (bool) {
        return LibBytes.endsWith(bytes(subject), bytes(needle));
    }
    function repeat(string memory subject, uint256 times) internal pure returns (string memory) {
        return string(LibBytes.repeat(bytes(subject), times));
    }
    function slice(string memory subject, uint256 start, uint256 end)
        internal
        pure
        returns (string memory)
    {
        return string(LibBytes.slice(bytes(subject), start, end));
    }
    function slice(string memory subject, uint256 start) internal pure returns (string memory) {
        return string(LibBytes.slice(bytes(subject), start, type(uint256).max));
    }
    function indicesOf(string memory subject, string memory needle)
        internal
        pure
        returns (uint256[] memory)
    {
        return LibBytes.indicesOf(bytes(subject), bytes(needle));
    }
    function split(string memory subject, string memory delimiter)
        internal
        pure
        returns (string[] memory result)
    {
        bytes[] memory a = LibBytes.split(bytes(subject), bytes(delimiter));
        assembly {
            result := a
        }
    }
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(LibBytes.concat(bytes(a), bytes(b)));
    }
    function toCase(string memory subject, bool toUpper)
        internal
        pure
        returns (string memory result)
    {
        assembly {
            let n := mload(subject)
            if n {
                result := mload(0x40)
                let o := add(result, 0x20)
                let d := sub(subject, result)
                let flags := shl(add(70, shl(5, toUpper)), 0x3ffffff)
                for { let end := add(o, n) } 1 {} {
                    let b := byte(0, mload(add(d, o)))
                    mstore8(o, xor(and(shr(b, flags), 0x20), b))
                    o := add(o, 1)
                    if eq(o, end) { break }
                }
                mstore(result, n)
                mstore(o, 0)
                mstore(0x40, add(o, 0x20))
            }
        }
    }
    function fromSmallString(bytes32 s) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let n := 0
            for {} byte(n, s) { n := add(n, 1) } {}
            mstore(result, n)
            let o := add(result, 0x20)
            mstore(o, s)
            mstore(add(o, n), 0)
            mstore(0x40, add(result, 0x40))
        }
    }
    function normalizeSmallString(bytes32 s) internal pure returns (bytes32 result) {
        assembly {
            for {} byte(result, s) { result := add(result, 1) } {}
            mstore(0x00, s)
            mstore(result, 0x00)
            result := mload(0x00)
        }
    }
    function toSmallString(string memory s) internal pure returns (bytes32 result) {
        assembly {
            result := mload(s)
            if iszero(lt(result, 33)) {
                mstore(0x00, 0xec92f9a3)
                revert(0x1c, 0x04)
            }
            result := shl(shl(3, sub(32, result)), mload(add(s, result)))
        }
    }
    function lower(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, false);
    }
    function upper(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, true);
    }
    function escapeHTML(string memory s) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let end := add(s, mload(s))
            let o := add(result, 0x20)
            mstore(0x1f, 0x900094)
            mstore(0x08, 0xc0000000a6ab)
            mstore(0x00, shl(64, 0x2671756f743b26616d703b262333393b266c743b2667743b))
            for {} iszero(eq(s, end)) {} {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                if iszero(and(shl(c, 1), 0x500000c400000000)) {
                    mstore8(o, c)
                    o := add(o, 1)
                    continue
                }
                let t := shr(248, mload(c))
                mstore(o, mload(and(t, 0x1f)))
                o := add(o, shr(5, t))
            }
            mstore(o, 0)
            mstore(result, sub(o, add(result, 0x20)))
            mstore(0x40, add(o, 0x20))
        }
    }
    function escapeJSON(string memory s, bool addDoubleQuotes)
        internal
        pure
        returns (string memory result)
    {
        assembly {
            result := mload(0x40)
            let o := add(result, 0x20)
            if addDoubleQuotes {
                mstore8(o, 34)
                o := add(1, o)
            }
            mstore(0x15, 0x5c75303030303031323334353637383961626364656662746e006672)
            let e := or(shl(0x22, 1), shl(0x5c, 1))
            for { let end := add(s, mload(s)) } iszero(eq(s, end)) {} {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                if iszero(lt(c, 0x20)) {
                    if iszero(and(shl(c, 1), e)) {
                        mstore8(o, c)
                        o := add(o, 1)
                        continue
                    }
                    mstore8(o, 0x5c)
                    mstore8(add(o, 1), c)
                    o := add(o, 2)
                    continue
                }
                if iszero(and(shl(c, 1), 0x3700)) {
                    mstore8(0x1d, mload(shr(4, c)))
                    mstore8(0x1e, mload(and(c, 15)))
                    mstore(o, mload(0x19))
                    o := add(o, 6)
                    continue
                }
                mstore8(o, 0x5c)
                mstore8(add(o, 1), mload(add(c, 8)))
                o := add(o, 2)
            }
            if addDoubleQuotes {
                mstore8(o, 34)
                o := add(1, o)
            }
            mstore(o, 0)
            mstore(result, sub(o, add(result, 0x20)))
            mstore(0x40, add(o, 0x20))
        }
    }
    function escapeJSON(string memory s) internal pure returns (string memory result) {
        result = escapeJSON(s, false);
    }
    function encodeURIComponent(string memory s) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            mstore(0x0f, 0x30313233343536373839414243444546)
            let o := add(result, 0x20)
            for { let end := add(s, mload(s)) } iszero(eq(s, end)) {} {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                if iszero(and(1, shr(c, 0x47fffffe87fffffe03ff678200000000))) {
                    mstore8(o, 0x25)
                    mstore8(add(o, 1), mload(and(shr(4, c), 15)))
                    mstore8(add(o, 2), mload(and(c, 15)))
                    o := add(o, 3)
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            mstore(result, sub(o, add(result, 0x20)))
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }
    function eq(string memory a, string memory b) internal pure returns (bool result) {
        assembly {
            result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
        }
    }
    function eqs(string memory a, bytes32 b) internal pure returns (bool result) {
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
    function cmp(string memory a, string memory b) internal pure returns (int256) {
        return LibBytes.cmp(bytes(a), bytes(b));
    }
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            result :=
                mul(
                    mload(add(a, 0x1f)),
                    lt(sub(mload(a), 1), 0x1f)
                )
        }
    }
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            mstore(0x40, add(result, 0x40))
            mstore(result, 0)
            mstore(add(result, 0x1f), packed)
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLen := mload(a)
            result :=
                mul(
                    or(
                    shl(shl(3, sub(0x1f, aLen)), mload(add(a, aLen))), mload(sub(add(b, 0x1e), aLen))),
                    lt(sub(add(aLen, mload(b)), 1), 0x1e)
                )
        }
    }
    function unpackTwo(bytes32 packed)
        internal
        pure
        returns (string memory resultA, string memory resultB)
    {
        assembly {
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            mstore(0x40, add(resultB, 0x40))
            mstore(resultA, 0)
            mstore(resultB, 0)
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }
    function directReturn(string memory a) internal pure {
        assembly {
            let retStart := sub(a, 0x20)
            let retUnpaddedSize := add(mload(a), 0x40)
            mstore(add(retStart, retUnpaddedSize), 0)
            mstore(retStart, 0x20)
            return(retStart, and(not(0x1f), add(0x1f, retUnpaddedSize)))
        }
    }
}