pragma solidity ^0.8.24;
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "./IResolver.sol";
abstract contract EssentialContract is UUPSUpgradeable, Ownable2StepUpgradeable {
    uint8 internal constant _FALSE = 1;
    uint8 internal constant _TRUE = 2;
    address private immutable __resolver;
    uint256[50] private __gapFromOldAddressResolver;
    uint8 internal __reentry;
    uint8 internal __paused;
    uint256[49] private __gap;
    event Paused(address account);
    event Unpaused(address account);
    error INVALID_PAUSE_STATUS();
    error FUNC_NOT_IMPLEMENTED();
    error REENTRANT_CALL();
    error ACCESS_DENIED();
    error RESOLVER_NOT_FOUND();
    error ZERO_ADDRESS();
    error ZERO_VALUE();
    modifier onlyFromOwnerOrNamed(bytes32 _name) {
        require(msg.sender == owner() || msg.sender == resolve(_name, true), ACCESS_DENIED());
        _;
    }
    modifier onlyFromOwnerOr(address _addr) {
        require(msg.sender == owner() || msg.sender == _addr, ACCESS_DENIED());
        _;
    }
    modifier notImplemented() {
        revert FUNC_NOT_IMPLEMENTED();
        _;
    }
    modifier nonReentrant() {
        require(_loadReentryLock() != _TRUE, REENTRANT_CALL());
        _storeReentryLock(_TRUE);
        _;
        _storeReentryLock(_FALSE);
    }
    modifier whenPaused() {
        require(paused(), INVALID_PAUSE_STATUS());
        _;
    }
    modifier whenNotPaused() {
        require(!paused(), INVALID_PAUSE_STATUS());
        _;
    }
    modifier nonZeroAddr(address _addr) {
        require(_addr != address(0), ZERO_ADDRESS());
        _;
    }
    modifier nonZeroValue(uint256 _value) {
        require(_value != 0, ZERO_VALUE());
        _;
    }
    modifier nonZeroBytes32(bytes32 _value) {
        require(_value != 0, ZERO_VALUE());
        _;
    }
    modifier onlyFromNamed(bytes32 _name) {
        require(msg.sender == resolve(_name, true), ACCESS_DENIED());
        _;
    }
    modifier onlyFromOptionalNamed(bytes32 _name) {
        address addr = resolve(_name, true);
        require(addr == address(0) || msg.sender == addr, ACCESS_DENIED());
        _;
    }
    modifier onlyFromNamedEither(bytes32 _name1, bytes32 _name2) {
        require(
            msg.sender == resolve(_name1, true) || msg.sender == resolve(_name2, true),
            ACCESS_DENIED()
        );
        _;
    }
    modifier onlyFromEither(address _addr1, address _addr2) {
        require(msg.sender == _addr1 || msg.sender == _addr2, ACCESS_DENIED());
        _;
    }
    modifier onlyFrom(address _addr) {
        require(msg.sender == _addr, ACCESS_DENIED());
        _;
    }
    modifier onlyFromOptional(address _addr) {
        require(_addr == address(0) || msg.sender == _addr, ACCESS_DENIED());
        _;
    }
    constructor(address _resolver) {
        __resolver = _resolver;
        _disableInitializers();
    }
    function pause() public whenNotPaused {
        _pause();
        emit Paused(msg.sender);
        _authorizePause(msg.sender, true);
    }
    function unpause() public whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
        _authorizePause(msg.sender, false);
    }
    function impl() public view returns (address) {
        return _getImplementation();
    }
    function paused() public view virtual returns (bool) {
        return __paused == _TRUE;
    }
    function inNonReentrant() public view returns (bool) {
        return _loadReentryLock() == _TRUE;
    }
    function resolver() public view virtual returns (address) {
        return __resolver;
    }
    function resolve(
        uint64 _chainId,
        bytes32 _name,
        bool _allowZeroAddress
    )
        internal
        view
        returns (address)
    {
        return IResolver(resolver()).resolve(_chainId, _name, _allowZeroAddress);
    }
    function resolve(bytes32 _name, bool _allowZeroAddress) internal view returns (address) {
        return IResolver(resolver()).resolve(uint64(block.chainid), _name, _allowZeroAddress);
    }
    function __Essential_init(address _owner) internal virtual onlyInitializing {
        __Context_init();
        _transferOwnership(_owner == address(0) ? msg.sender : _owner);
        __paused = _FALSE;
    }
    function _pause() internal virtual {
        __paused = _TRUE;
    }
    function _unpause() internal virtual {
        __paused = _FALSE;
    }
    function _authorizeUpgrade(address) internal virtual override onlyOwner { }
    function _authorizePause(address, bool) internal virtual onlyOwner { }
    function _storeReentryLock(uint8 _reentry) internal virtual {
        __reentry = _reentry;
    }
    function _loadReentryLock() internal view virtual returns (uint8 reentry_) {
        reentry_ = __reentry;
    }
}