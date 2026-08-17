pragma solidity 0.8.12;
import "./VaultManagerERC721.sol";
import "../interfaces/external/IERC1271.sol";
abstract contract VaultManagerPermit is Initializable, VaultManagerERC721 {
    using Address for address;
    mapping(address => uint256) private _nonces;
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _PERMIT_TYPEHASH;
    error ExpiredDeadline();
    error InvalidSignature();
    function __ERC721Permit_init(string memory _name) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,bool approved,uint256 nonce,uint256 deadline)");
        _HASHED_NAME = keccak256(bytes(_name));
        _HASHED_VERSION = keccak256(bytes("1"));
    }
    function permit(
        address owner,
        address spender,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) revert ExpiredDeadline();
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 || (v != 27 && v != 28))
            revert InvalidSignature();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        _PERMIT_TYPEHASH,
                        owner,
                        spender,
                        approved,
                        _useNonce(owner),
                        deadline
                    )
                )
            )
        );
        if (owner.isContract()) {
            if (IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) != 0x1626ba7e) revert InvalidSignature();
        } else {
            address signer = ecrecover(digest, v, r, s);
            if (signer != owner || signer == address(0)) revert InvalidSignature();
        }
        _setApprovalForAll(owner, spender, approved);
    }
    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    _HASHED_NAME,
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }
    function _useNonce(address owner) internal returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] = current + 1;
    }
    uint256[49] private __gap;
}