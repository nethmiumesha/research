pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TestToken.sol";
contract TokenFactory {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _tokens;
    event TokenCreated(address indexed token);
    constructor() {
    }
    function getTotalTokens() external view returns (uint256) {
        return _tokens.length();
    }
    function getTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        require((end >= start) && (end - start) <= _tokens.length(), "OUT_OF_BOUNDS");
        address[] memory token = new address[](end - start);
        for (uint256 i = 0; i < token.length; ++i) {
            token[i] = _tokens.at(i + start);
        }
        return token;
    }
    function create(
        address admin,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address) {
        bytes memory creationCode = abi.encodePacked(
            type(TestToken).creationCode,
            abi.encode(admin, name, symbol, decimals)
        );
        address expectedToken = Create2.computeAddress(0, keccak256(creationCode));
        if (expectedToken.isContract()) {
            return expectedToken;
        } else {
            address token = Create2.deploy(0, 0, creationCode);
            assert(token == expectedToken);
            _tokens.add(token);
            emit TokenCreated(token);
            return token;
        }
    }
}