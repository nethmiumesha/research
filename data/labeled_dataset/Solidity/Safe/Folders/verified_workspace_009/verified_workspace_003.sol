pragma solidity 0.7.5;
import "../../../upgradeability/Proxy.sol";
interface IPermittableTokenVersion {
    function version() external pure returns (string memory);
}
contract TokenProxy is Proxy {
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply;
    mapping(address => mapping(address => uint256)) internal allowed;
    address internal owner;
    bool internal mintingFinished;
    address internal bridgeContractAddr;
    bytes32 internal DOMAIN_SEPARATOR;
    mapping(address => uint256) internal nonces;
    mapping(address => mapping(address => uint256)) internal expirations;
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _chainId,
        address _owner
    ) {
        string memory version = IPermittableTokenVersion(_tokenImage).version();
        assembly {
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = _owner;
        bridgeContractAddr = _owner;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }
}