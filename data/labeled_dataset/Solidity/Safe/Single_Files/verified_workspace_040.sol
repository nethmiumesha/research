pragma solidity =0.8.24;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract Pausable is Context {
    bool private _paused;
    event Paused(address account);
    event Unpaused(address account);
    error EnforcedPause();
    error ExpectedPause();
    constructor() {
        _paused = false;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC1363 is IERC20, IERC165 {
    function transferAndCall(address to, uint256 value) external returns (bool);
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
    function approveAndCall(address spender, uint256 value)
        external
        returns (bool);
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
}
library SafeERC20 {
    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 requestedDecrease
    );
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeCall(token.transferFrom, (from, to, value))
        );
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 requestedDecrease
    ) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(
                    spender,
                    currentAllowance,
                    requestedDecrease
                );
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            token.approve,
            (spender, value)
        );
        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeCall(token.approve, (spender, 0))
            );
            _callOptionalReturn(token, approvalCall);
        }
    }
    function transferAndCallRelaxed(
        IERC1363 token,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
    function approveAndCallRelaxed(
        IERC1363 token,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(
                gas(),
                token,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0x20
            )
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        if (
            returnSize == 0 ? address(token).code.length == 0 : returnValue != 1
        ) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
    function _callOptionalReturnBool(IERC20 token, bytes memory data)
        private
        returns (bool)
    {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(
                gas(),
                token,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0x20
            )
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return
            success &&
            (
                returnSize == 0
                    ? address(token).code.length > 0
                    : returnValue == 1
            );
    }
}
library Panic {
    uint256 internal constant GENERIC = 0x00;
    uint256 internal constant ASSERT = 0x01;
    uint256 internal constant UNDER_OVERFLOW = 0x11;
    uint256 internal constant DIVISION_BY_ZERO = 0x12;
    uint256 internal constant ENUM_CONVERSION_ERROR = 0x21;
    uint256 internal constant STORAGE_ENCODING_ERROR = 0x22;
    uint256 internal constant EMPTY_ARRAY_POP = 0x31;
    uint256 internal constant ARRAY_OUT_OF_BOUNDS = 0x32;
    uint256 internal constant RESOURCE_ERROR = 0x41;
    uint256 internal constant INVALID_INTERNAL_FUNCTION = 0x51;
    function panic(uint256 code) internal pure {
        assembly ("memory-safe") {
            mstore(0x00, 0x4e487b71)
            mstore(0x20, code)
            revert(0x1c, 0x24)
        }
    }
}
library SafeCast {
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeCastOverflowedIntToUint(int256 value);
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);
    error SafeCastOverflowedUintToInt(uint256 value);
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }
    function toInt256(uint256 value) internal pure returns (int256) {
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
    function toUint(bool b) internal pure returns (uint256 u) {
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}
library Math {
    enum Rounding {
        Floor,
        Ceil,
        Trunc,
        Expand
    }
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool success, uint256 result)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool success, uint256 result)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool success, uint256 result)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool success, uint256 result)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool success, uint256 result)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function ternary(
        bool condition,
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        unchecked {
            return b ^ ((a ^ b) * SafeCast.toUint(condition));
        }
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a > b, a, b);
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a < b, a, b);
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        unchecked {
            return SafeCast.toUint(a > 0) * ((a - 1) / b + 1);
        }
    }
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0 = x * y;
            uint256 prod1;
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (prod1 == 0) {
                return prod0 / denominator;
            }
            if (denominator <= prod1) {
                Panic.panic(
                    ternary(
                        denominator == 0,
                        Panic.DIVISION_BY_ZERO,
                        Panic.UNDER_OVERFLOW
                    )
                );
            }
            uint256 remainder;
            assembly {
                remainder := mulmod(x, y, denominator)
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            uint256 twos = denominator & (0 - denominator);
            assembly {
                denominator := div(denominator, twos)
                prod0 := div(prod0, twos)
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            result = prod0 * inverse;
            return result;
        }
    }
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        return
            mulDiv(x, y, denominator) +
            SafeCast.toUint(
                unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0
            );
    }
    function invMod(uint256 a, uint256 n) internal pure returns (uint256) {
        unchecked {
            if (n == 0) return 0;
            uint256 remainder = a % n;
            uint256 gcd = n;
            int256 x = 0;
            int256 y = 1;
            while (remainder != 0) {
                uint256 quotient = gcd / remainder;
                (gcd, remainder) = (
                    remainder,
                    gcd - remainder * quotient
                );
                (x, y) = (
                    y,
                    x - y * int256(quotient)
                );
            }
            if (gcd != 1) return 0;
            return ternary(x < 0, n - uint256(-x), uint256(x));
        }
    }
    function invModPrime(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            return Math.modExp(a, p - 2, p);
        }
    }
    function modExp(
        uint256 b,
        uint256 e,
        uint256 m
    ) internal view returns (uint256) {
        (bool success, uint256 result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }
    function tryModExp(
        uint256 b,
        uint256 e,
        uint256 m
    ) internal view returns (bool success, uint256 result) {
        if (m == 0) return (false, 0);
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), 0x20)
            mstore(add(ptr, 0x40), 0x20)
            mstore(add(ptr, 0x60), b)
            mstore(add(ptr, 0x80), e)
            mstore(add(ptr, 0xa0), m)
            success := staticcall(gas(), 0x05, ptr, 0xc0, 0x00, 0x20)
            result := mload(0x00)
        }
    }
    function modExp(
        bytes memory b,
        bytes memory e,
        bytes memory m
    ) internal view returns (bytes memory) {
        (bool success, bytes memory result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }
    function tryModExp(
        bytes memory b,
        bytes memory e,
        bytes memory m
    ) internal view returns (bool success, bytes memory result) {
        if (_zeroBytes(m)) return (false, new bytes(0));
        uint256 mLen = m.length;
        result = abi.encodePacked(b.length, e.length, mLen, b, e, m);
        assembly ("memory-safe") {
            let dataPtr := add(result, 0x20)
            success := staticcall(
                gas(),
                0x05,
                dataPtr,
                mload(result),
                dataPtr,
                mLen
            )
            mstore(result, mLen)
            mstore(0x40, add(dataPtr, mLen))
        }
    }
    function _zeroBytes(bytes memory byteArray) private pure returns (bool) {
        for (uint256 i = 0; i < byteArray.length; ++i) {
            if (byteArray[i] != 0) {
                return false;
            }
        }
        return true;
    }
    function sqrt(uint256 a) internal pure returns (uint256) {
        unchecked {
            if (a <= 1) {
                return a;
            }
            uint256 aa = a;
            uint256 xn = 1;
            if (aa >= (1 << 128)) {
                aa >>= 128;
                xn <<= 64;
            }
            if (aa >= (1 << 64)) {
                aa >>= 64;
                xn <<= 32;
            }
            if (aa >= (1 << 32)) {
                aa >>= 32;
                xn <<= 16;
            }
            if (aa >= (1 << 16)) {
                aa >>= 16;
                xn <<= 8;
            }
            if (aa >= (1 << 8)) {
                aa >>= 8;
                xn <<= 4;
            }
            if (aa >= (1 << 4)) {
                aa >>= 4;
                xn <<= 2;
            }
            if (aa >= (1 << 2)) {
                xn <<= 1;
            }
            xn = (3 * xn) >> 1;
            xn = (xn + a / xn) >> 1;
            xn = (xn + a / xn) >> 1;
            xn = (xn + a / xn) >> 1;
            xn = (xn + a / xn) >> 1;
            xn = (xn + a / xn) >> 1;
            xn = (xn + a / xn) >> 1;
            return xn - SafeCast.toUint(xn > a / xn);
        }
    }
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                SafeCast.toUint(
                    unsignedRoundsUp(rounding) && result * result < a
                );
        }
    }
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 exp;
        unchecked {
            exp = 128 * SafeCast.toUint(value > (1 << 128) - 1);
            value >>= exp;
            result += exp;
            exp = 64 * SafeCast.toUint(value > (1 << 64) - 1);
            value >>= exp;
            result += exp;
            exp = 32 * SafeCast.toUint(value > (1 << 32) - 1);
            value >>= exp;
            result += exp;
            exp = 16 * SafeCast.toUint(value > (1 << 16) - 1);
            value >>= exp;
            result += exp;
            exp = 8 * SafeCast.toUint(value > (1 << 8) - 1);
            value >>= exp;
            result += exp;
            exp = 4 * SafeCast.toUint(value > (1 << 4) - 1);
            value >>= exp;
            result += exp;
            exp = 2 * SafeCast.toUint(value > (1 << 2) - 1);
            value >>= exp;
            result += exp;
            result += SafeCast.toUint(value > 1);
        }
        return result;
    }
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                SafeCast.toUint(
                    unsignedRoundsUp(rounding) && 1 << result < value
                );
        }
    }
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                SafeCast.toUint(
                    unsignedRoundsUp(rounding) && 10**result < value
                );
        }
    }
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 isGt;
        unchecked {
            isGt = SafeCast.toUint(value > (1 << 128) - 1);
            value >>= isGt * 128;
            result += isGt * 16;
            isGt = SafeCast.toUint(value > (1 << 64) - 1);
            value >>= isGt * 64;
            result += isGt * 8;
            isGt = SafeCast.toUint(value > (1 << 32) - 1);
            value >>= isGt * 32;
            result += isGt * 4;
            isGt = SafeCast.toUint(value > (1 << 16) - 1);
            value >>= isGt * 16;
            result += isGt * 2;
            result += SafeCast.toUint(value > (1 << 8) - 1);
        }
        return result;
    }
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                SafeCast.toUint(
                    unsignedRoundsUp(rounding) && 1 << (result << 3) < value
                );
        }
    }
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}
library SignedMath {
    function ternary(
        bool condition,
        int256 a,
        int256 b
    ) internal pure returns (int256) {
        unchecked {
            return b ^ ((a ^ b) * int256(SafeCast.toUint(condition)));
        }
    }
    function max(int256 a, int256 b) internal pure returns (int256) {
        return ternary(a > b, a, b);
    }
    function min(int256 a, int256 b) internal pure returns (int256) {
        return ternary(a < b, a, b);
    }
    function average(int256 a, int256 b) internal pure returns (int256) {
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            int256 mask = n >> 255;
            return uint256((n + mask) ^ mask);
        }
    }
}
library Strings {
    using SafeCast for *;
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;
    error StringsInsufficientHexLength(uint256 value, uint256 length);
    error StringsInvalidChar();
    error StringsInvalidAddressFormat();
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly ("memory-safe") {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly ("memory-safe") {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
    function toStringSigned(int256 value)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                value < 0 ? "-" : "",
                toString(SignedMath.abs(value))
            );
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }
    function toChecksumHexString(address addr)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = bytes(toHexString(addr));
        uint256 hashValue;
        assembly ("memory-safe") {
            hashValue := shr(96, keccak256(add(buffer, 0x22), 40))
        }
        for (uint256 i = 41; i > 1; --i) {
            if (hashValue & 0xf > 7 && uint8(buffer[i]) > 96) {
                buffer[i] ^= 0x20;
            }
            hashValue >>= 4;
        }
        return string(buffer);
    }
    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }
    function parseUint(string memory input) internal pure returns (uint256) {
        return parseUint(input, 0, bytes(input).length);
    }
    function parseUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (uint256) {
        (bool success, uint256 value) = tryParseUint(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }
    function tryParseUint(string memory input)
        internal
        pure
        returns (bool success, uint256 value)
    {
        return _tryParseUintUncheckedBounds(input, 0, bytes(input).length);
    }
    function tryParseUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseUintUncheckedBounds(input, begin, end);
    }
    function _tryParseUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {
        bytes memory buffer = bytes(input);
        uint256 result = 0;
        for (uint256 i = begin; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));
            if (chr > 9) return (false, 0);
            result *= 10;
            result += chr;
        }
        return (true, result);
    }
    function parseInt(string memory input) internal pure returns (int256) {
        return parseInt(input, 0, bytes(input).length);
    }
    function parseInt(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (int256) {
        (bool success, int256 value) = tryParseInt(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }
    function tryParseInt(string memory input)
        internal
        pure
        returns (bool success, int256 value)
    {
        return _tryParseIntUncheckedBounds(input, 0, bytes(input).length);
    }
    uint256 private constant ABS_MIN_INT256 = 2**255;
    function tryParseInt(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, int256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseIntUncheckedBounds(input, begin, end);
    }
    function _tryParseIntUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, int256 value) {
        bytes memory buffer = bytes(input);
        bytes1 sign = begin == end
            ? bytes1(0)
            : bytes1(_unsafeReadBytesOffset(buffer, begin));
        bool positiveSign = sign == bytes1("+");
        bool negativeSign = sign == bytes1("-");
        uint256 offset = (positiveSign || negativeSign).toUint();
        (bool absSuccess, uint256 absValue) = tryParseUint(
            input,
            begin + offset,
            end
        );
        if (absSuccess && absValue < ABS_MIN_INT256) {
            return (true, negativeSign ? -int256(absValue) : int256(absValue));
        } else if (absSuccess && negativeSign && absValue == ABS_MIN_INT256) {
            return (true, type(int256).min);
        } else return (false, 0);
    }
    function parseHexUint(string memory input) internal pure returns (uint256) {
        return parseHexUint(input, 0, bytes(input).length);
    }
    function parseHexUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (uint256) {
        (bool success, uint256 value) = tryParseHexUint(input, begin, end);
        if (!success) revert StringsInvalidChar();
        return value;
    }
    function tryParseHexUint(string memory input)
        internal
        pure
        returns (bool success, uint256 value)
    {
        return _tryParseHexUintUncheckedBounds(input, 0, bytes(input).length);
    }
    function tryParseHexUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseHexUintUncheckedBounds(input, begin, end);
    }
    function _tryParseHexUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {
        bytes memory buffer = bytes(input);
        bool hasPrefix = (end > begin + 1) &&
            bytes2(_unsafeReadBytesOffset(buffer, begin)) == bytes2("0x");
        uint256 offset = hasPrefix.toUint() * 2;
        uint256 result = 0;
        for (uint256 i = begin + offset; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));
            if (chr > 15) return (false, 0);
            result *= 16;
            unchecked {
                result += chr;
            }
        }
        return (true, result);
    }
    function parseAddress(string memory input) internal pure returns (address) {
        return parseAddress(input, 0, bytes(input).length);
    }
    function parseAddress(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (address) {
        (bool success, address value) = tryParseAddress(input, begin, end);
        if (!success) revert StringsInvalidAddressFormat();
        return value;
    }
    function tryParseAddress(string memory input)
        internal
        pure
        returns (bool success, address value)
    {
        return tryParseAddress(input, 0, bytes(input).length);
    }
    function tryParseAddress(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, address value) {
        if (end > bytes(input).length || begin > end)
            return (false, address(0));
        bool hasPrefix = (end > begin + 1) &&
            bytes2(_unsafeReadBytesOffset(bytes(input), begin)) == bytes2("0x");
        uint256 expectedLength = 40 + hasPrefix.toUint() * 2;
        if (end - begin == expectedLength) {
            (bool s, uint256 v) = _tryParseHexUintUncheckedBounds(
                input,
                begin,
                end
            );
            return (s, address(uint160(v)));
        } else {
            return (false, address(0));
        }
    }
    function _tryParseChr(bytes1 chr) private pure returns (uint8) {
        uint8 value = uint8(chr);
        unchecked {
            if (value > 47 && value < 58) value -= 48;
            else if (value > 96 && value < 103) value -= 87;
            else if (value > 64 && value < 71) value -= 55;
            else return type(uint8).max;
        }
        return value;
    }
    function _unsafeReadBytesOffset(bytes memory buffer, uint256 offset)
        private
        pure
        returns (bytes32 value)
    {
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }
}
library MessageHashUtils {
    function toEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32 digest)
    {
        assembly ("memory-safe") {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, messageHash)
            digest := keccak256(0x00, 0x3c)
        }
    }
    function toEthSignedMessageHash(bytes memory message)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    "\x19Ethereum Signed Message:\n",
                    bytes(Strings.toString(message.length)),
                    message
                )
            );
    }
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32 digest)
    {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}
library StorageSlot {
    struct AddressSlot {
        address value;
    }
    struct BooleanSlot {
        bool value;
    }
    struct Bytes32Slot {
        bytes32 value;
    }
    struct Uint256Slot {
        uint256 value;
    }
    struct Int256Slot {
        int256 value;
    }
    struct StringSlot {
        string value;
    }
    struct BytesSlot {
        bytes value;
    }
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getInt256Slot(bytes32 slot)
        internal
        pure
        returns (Int256Slot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getStringSlot(bytes32 slot)
        internal
        pure
        returns (StringSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getStringSlot(string storage store)
        internal
        pure
        returns (StringSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
    function getBytesSlot(bytes32 slot)
        internal
        pure
        returns (BytesSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
    function getBytesSlot(bytes storage store)
        internal
        pure
        returns (BytesSlot storage r)
    {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}
type ShortString is bytes32;
library ShortStrings {
    bytes32 private constant FALLBACK_SENTINEL =
        0x00000000000000000000000000000000000000000000000000000000000000FF;
    error StringTooLong(string str);
    error InvalidShortString();
    function toShortString(string memory str)
        internal
        pure
        returns (ShortString)
    {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        string memory str = new string(32);
        assembly ("memory-safe") {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }
    function toShortStringWithFallback(
        string memory value,
        string storage store
    ) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(FALLBACK_SENTINEL);
        }
    }
    function toStringWithFallback(ShortString value, string storage store)
        internal
        pure
        returns (string memory)
    {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }
    function byteLengthWithFallback(ShortString value, string storage store)
        internal
        view
        returns (uint256)
    {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}
interface IERC5267 {
    event EIP712DomainChanged();
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;
    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;
    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;
    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));
        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }
    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f",
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
    function _EIP712Name() internal view returns (string memory) {
        return _name.toStringWithFallback(_nameFallback);
    }
    function _EIP712Version() internal view returns (string memory) {
        return _version.toStringWithFallback(_versionFallback);
    }
}
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }
    error ECDSAInvalidSignature();
    error ECDSAInvalidSignatureLength(uint256 length);
    error ECDSAInvalidSignatureS(bytes32 s);
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (
            address recovered,
            RecoverError err,
            bytes32 errArg
        )
    {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly ("memory-safe") {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (
                address(0),
                RecoverError.InvalidSignatureLength,
                bytes32(signature.length)
            );
        }
    }
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            signature
        );
        _throwError(error, errorArg);
        return recovered;
    }
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    )
        internal
        pure
        returns (
            address recovered,
            RecoverError err,
            bytes32 errArg
        )
    {
        unchecked {
            bytes32 s = vs &
                bytes32(
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                );
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            r,
            vs
        );
        _throwError(error, errorArg);
        return recovered;
    }
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (
            address recovered,
            RecoverError err,
            bytes32 errArg
        )
    {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }
        return (signer, RecoverError.NoError, bytes32(0));
    }
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            v,
            r,
            s
        );
        _throwError(error, errorArg);
        return recovered;
    }
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return;
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        if (signer.code.length == 0) {
            (address recovered, ECDSA.RecoverError err, ) = ECDSA.tryRecover(
                hash,
                signature
            );
            return err == ECDSA.RecoverError.NoError && recovered == signer;
        } else {
            return isValidERC1271SignatureNow(signer, hash, signature);
        }
    }
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (hash, signature))
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) ==
            bytes32(IERC1271.isValidSignature.selector));
    }
}
abstract contract Nonces {
    error InvalidAccountNonce(address account, uint256 currentNonce);
    mapping(address => uint256) private _nonces;
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }
    function _useNonce(address owner) internal virtual returns (uint256) {
        unchecked {
            return _nonces[owner]++;
        }
    }
    function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
        uint256 current = _useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}
library Errors {
    error InsufficientBalance(uint256 balance, uint256 needed);
    error FailedCall();
    error FailedDeployment();
    error MissingPrecompile(address);
}
library Address {
    error AddressEmptyCode(address target);
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }
        (bool success, bytes memory returndata) = recipient.call{value: amount}(
            ""
        );
        if (!success) {
            _revert(returndata);
        }
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }
    function verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }
    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly ("memory-safe") {
                revert(add(returndata, 0x20), mload(returndata))
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}
contract SwagGoldIco is EIP712, Ownable, Nonces, Pausable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Address for address;
    HashUtility public hashUtility;
    IERC20 public swag;
    address public signer;
    uint256 public expiryBlock = 80;
    enum UpdateFlag {
        Swag,
        Signer
    }
    struct HashUtility {
        address proofVerifier;
        bytes4 actionId;
    }
    mapping(address => bool) public whitelistedTkns;
    mapping(address => uint256) public userDetails;
    event Buy(
        address indexed buyer,
        address indexed tkn,
        uint256 price,
        uint256 amount,
        uint256 blkNo
    );
    event Update(
        uint256 indexed flag,
        address indexed oldAccount,
        address indexed account
    );
    event AdminWithdraw(
        address indexed to,
        address indexed tokenAddress,
        uint256 amount
    );
    modifier onlyWhitelisted(address tkn) {
        require(whitelistedTkns[tkn], "SwagIco: not whitelisted");
        _;
    }
    constructor(
        IERC20 initSwag,
        address initUsdt,
        address initOwner,
        address initSigner,
        address _proofVerifier
    ) Ownable(initOwner) EIP712("SWAGG", "1") {
        require(initOwner != address(0), "SwagIco: zero owner");
        require(initSigner != address(0), "SwagIco: zero signer");
        require(address(initSwag) != address(0), "SwagIco: zero swag");
        require(initUsdt != address(0), "SwagIco: zero usdt");
        swag = initSwag;
        signer = initSigner;
        whitelistedTkns[address(0)] = true;
        whitelistedTkns[initUsdt] = true;
        hashUtility.proofVerifier = _proofVerifier;
        hashUtility.actionId = 0x5ec2ca1a;
    }
    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "SwagIco: zero signer");
        address oldSigner = signer;
        signer = newSigner;
        emit Update(uint256(UpdateFlag.Signer), oldSigner, newSigner);
    }
    function setSwag(IERC20 newSwag) external onlyOwner {
        require(address(newSwag) != address(0), "SwagIco: zero swag");
        address oldSwag = address(swag);
        swag = newSwag;
        emit Update(uint256(UpdateFlag.Swag), oldSwag, address(newSwag));
    }
    function setExpiryBlk(uint256 newExpiry) external onlyOwner {
        require(newExpiry != 0, "SwagIco: zero expiry");
        expiryBlock = newExpiry;
    }
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
    function setProofVerifier(address _proofVerifier) public onlyOwner {
        require(
            _proofVerifier != address(0),
            "MessageDigestHelper::Invalid address"
        );
        hashUtility.proofVerifier = _proofVerifier;
    }
    function setActionId(bytes4 _actionId) public onlyOwner {
        hashUtility.actionId = _actionId;
    }
    function addTknToWhitelist(address[] calldata tkn) external onlyOwner {
        for (uint256 i = 0; i < tkn.length; i++) {
            _addTknToWhitelist(tkn[i]);
        }
    }
    function rmTknToWhitelist(address[] calldata tkn) external onlyOwner {
        for (uint256 i = 0; i < tkn.length; i++) {
            _rmTknToWhitelist(tkn[i]);
        }
    }
    function buy(
        address tkn,
        uint256 price,
        uint256 amount,
        uint256 deadBlk,
        bytes memory signature
    ) public payable whenNotPaused onlyWhitelisted(tkn) {
        address buyer = _msgSender();
        uint256 currentBlk = block.number;
        require(price != 0, "SwagIco: zero price");
        require(amount != 0, "SwagIco: zero amount");
        require(
            deadBlk > currentBlk && deadBlk <= currentBlk + expiryBlock,
            "SwagIco: deadblk reached"
        );
        address keyer = _validateSign(
            buyer,
            tkn,
            price,
            amount,
            deadBlk,
            signature
        );
        require(keyer == signer, "Invalid Signature!");
        _useNonce(buyer);
        (tkn == address(0)) ? _buyETH(price) : _buyTkn(buyer, tkn, price);
        _sendSwag(buyer, amount);
        emit Buy(buyer, tkn, price, amount, currentBlk);
    }
    function retrieve(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "SwagIco: invalid to");
        if (_tokenAddress == address(0)) {
            require(
                address(this).balance >= _amount,
                "SwagIco: not enough eth"
            );
            require(payable(_to).send(_amount), "SwagIco: ETH transfer failed");
        } else {
            require(
                IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
                "SwagIco: insufficient tokn balance"
            );
            IERC20(_tokenAddress).safeTransfer(_to, _amount);
        }
        emit AdminWithdraw(_to, _tokenAddress, _amount);
    }
    function _validateSign(
        address _caller,
        address _tkn,
        uint256 _price,
        uint256 _amount,
        uint256 _deadBlk,
        bytes memory _signature
    ) public view returns (address keyer) {
        bytes memory structHash = abi.encode(
            _caller,
            _tkn,
            _price,
            _amount,
            nonces(_caller),
            _deadBlk
        );
        bytes memory data = abi.encodeWithSelector(hashUtility.actionId,structHash);
        bytes memory result = hashUtility.proofVerifier.functionStaticCall(data);
        bytes32 digest = _hashTypedDataV4(abi.decode(result, (bytes32)));
        keyer = ECDSA.recover(digest, _signature);
    }
    function _buyETH(uint256 _price) private {
        require(_price == msg.value, "SwagIco: incorrect price");
        require(payable(owner()).send(_price), "SwagIco: ETH transfer failed");
    }
    function _buyTkn(
        address _caller,
        address _tkn,
        uint256 _price
    ) private {
        require(_tkn != address(0), "SwagIco: incorrect tkn");
        require(msg.value == 0, "SwagIco: incorrect eth value");
        IERC20(_tkn).safeTransferFrom(_caller, owner(), _price);
    }
    function _sendSwag(address _caller, uint256 _amount) private {
        require(
            swag.balanceOf(address(this)) >= _amount,
            "SwagIco: insufficient balance"
        );
        userDetails[_caller] += _amount;
        swag.safeTransfer(_caller, _amount);
    }
    function _addTknToWhitelist(address tkn) private {
        require(!whitelistedTkns[tkn], "SwagIco: whitelisted tkn");
        whitelistedTkns[tkn] = true;
    }
    function _rmTknToWhitelist(address _tkn) private {
        require(whitelistedTkns[_tkn], "SwagIco: not whitelisted");
        whitelistedTkns[_tkn] = false;
    }
}