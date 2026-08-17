pragma solidity ^0.4.25;
import "./ownable.sol";
import "./controllable.sol";
import "./claimable.sol";
import "../externals/strings.sol";
import "../externals/SafeMath.sol";
interface ITokenWhitelist {
    function getTokenInfo(address) external view returns (string, uint256, uint256, bool, bool, bool, uint256);
    function getStablecoinInfo() external view returns (string, uint256, uint256, bool, bool, bool, uint256);
    function tokenAddressArray() external view returns (address[]);
    function updateTokenRate(address, uint, uint) external;
    function stablecoin() external view returns (address);
}
contract TokenWhitelist is ENSResolvable, Controllable, Ownable, Claimable {
    using strings for *;
    using SafeMath for uint256;
    event UpdatedTokenRate(address _sender, address _token, uint _rate);
    event AddedToken(address _sender, address _token, string _symbol, uint _magnitude, bool _loadable, bool _burnable);
    event RemovedToken(address _sender, address _token);
    struct Token {
        string symbol;
        uint magnitude;
        uint rate;
        bool available;
        bool loadable;
        bool burnable;
        uint lastUpdate;
    }
    mapping(address => Token) private _tokenInfoMap;
    address[] private _tokenAddressArray;
    modifier onlyControllerOrOracle() {
        address oracleAddress = _ensResolve(_oracleNode);
        require (_isController(msg.sender) || msg.sender == oracleAddress, "either oracle or controller");
        _;
    }
    address private _stablecoin;
    bytes32 private _oracleNode;
    constructor(address _ens_, bytes32 _oracleNameHash_, bytes32 _controllerNameHash_, address _owner_, bool _transferable_, address _stabelcoinAddress_) ENSResolvable(_ens_) Controllable(_controllerNameHash_) Ownable(_owner_, _transferable_) public {
        _oracleNode = _oracleNameHash_;
        _stablecoin = _stabelcoinAddress_;
    }
    function addTokens(address[] _tokens, bytes32[] _symbols, uint[] _magnitude, bool[] _loadable, bool[] _burnable, uint _lastUpdate) external onlyController {
        require(_tokens.length == _symbols.length && _tokens.length == _magnitude.length && _tokens.length == _loadable.length && _tokens.length == _loadable.length, "parameter lengths do not match");
        for (uint i = 0; i < _tokens.length; i++) {
            require(!_tokenInfoMap[_tokens[i]].available, "token already available");
            string memory symbol = _symbols[i].toSliceB32().toString();
            _tokenInfoMap[_tokens[i]] = Token({
                symbol : symbol,
                magnitude : _magnitude[i],
                rate : 0,
                available : true,
                loadable : _loadable[i],
                burnable: _burnable[i],
                lastUpdate : _lastUpdate
                });
            _tokenAddressArray.push(_tokens[i]);
            emit AddedToken(msg.sender, _tokens[i], symbol, _magnitude[i], _loadable[i], _burnable[i]);
        }
    }
    function removeTokens(address[] _tokens) external onlyController {
        for (uint i = 0; i < _tokens.length; i++) {
            require(_tokenInfoMap[_tokens[i]].available, "token is not available");
            address token = _tokens[i];
            delete _tokenInfoMap[token];
            for (uint j = 0; j < _tokenAddressArray.length.sub(1); j++) {
                if (_tokenAddressArray[j] == token) {
                    _tokenAddressArray[j] = _tokenAddressArray[_tokenAddressArray.length.sub(1)];
                    break;
                }
            }
            _tokenAddressArray.length--;
            emit RemovedToken(msg.sender, token);
        }
    }
    function updateTokenRate(address _token, uint _rate, uint _updateDate) external onlyControllerOrOracle {
        require(_tokenInfoMap[_token].available, "token is not available");
        _tokenInfoMap[_token].rate = _rate;
        _tokenInfoMap[_token].lastUpdate = _updateDate;
        emit UpdatedTokenRate(msg.sender, _token, _rate);
    }
    function claim(address _to, address _asset, uint _amount) external onlyOwner {
        _claim(_to, _asset, _amount);
    }
    function getTokenInfo(address _a) external view returns (string, uint256, uint256, bool, bool, bool, uint256) {
        Token storage tokenInfo = _tokenInfoMap[_a];
        return (tokenInfo.symbol, tokenInfo.magnitude, tokenInfo.rate, tokenInfo.available, tokenInfo.loadable, tokenInfo.burnable, tokenInfo.lastUpdate);
    }
    function getStablecoinInfo() external view returns (string, uint256, uint256, bool, bool, bool, uint256) {
        Token storage stablecoinInfo = _tokenInfoMap[_stablecoin];
        return (stablecoinInfo.symbol, stablecoinInfo.magnitude, stablecoinInfo.rate, stablecoinInfo.available, stablecoinInfo.loadable, stablecoinInfo.burnable, stablecoinInfo.lastUpdate);
    }
    function tokenAddressArray() external view returns (address[]) {
        return _tokenAddressArray;
    }
    function stablecoin() external view returns (address) {
        return _stablecoin;
    }
    function oracleNode() external view returns (bytes32) {
        return _oracleNode;
    }
}