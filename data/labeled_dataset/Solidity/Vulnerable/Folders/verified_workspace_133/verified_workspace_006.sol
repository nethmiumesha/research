pragma solidity ^0.8.22;
import "./MsgEnvironment.sol";
import "./IReadableDeclaration.sol";
import "./IAssetProperties.sol";
abstract contract LiteDesign is MsgEnvironment, IAssetProperties {
    mapping(address => uint256) private _userBalances;
    mapping(address => mapping(address => uint256)) private _approvedAmounts;
    uint256 private _totalSupply;
    string private _displayName;
    string private _shortName;
    constructor(string memory n_, string memory s_) { _displayName = n_; _shortName = s_; }
    function name() public view virtual override returns (string memory) { return _displayName; }
    function symbol() public view virtual override returns (string memory) { return _shortName; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address a) public view virtual override returns (uint256) { return _userBalances[a]; }
    function transfer(address to, uint256 amt) public virtual override returns (bool) { _transfer(_msgSender(), to, amt); return true; }
    function allowance(address o, address s) public view virtual override returns (uint256) { return _approvedAmounts[o][s]; }
    function approve(address s, uint256 amt) public virtual override returns (bool) { _approve(_msgSender(), s, amt); return true; }
    function transferFrom(address f, address t, uint256 amt) public virtual override returns (bool) { _spendAllowance(f, _msgSender(), amt); _transfer(f, t, amt); return true; }
    function _transfer(address f, address t, uint256 amt) internal virtual {
        require(f != address(0) && t != address(0), "ERC20: to the zero address");
        uint256 bal = _userBalances[f]; require(bal >= amt, "Not enough tokens");
        unchecked { _userBalances[f] = bal - amt; _userBalances[t] += amt; }
        emit Transfer(f, t, amt);
    }
    function _mint(address a, uint256 amt) internal virtual {
        require(a != address(0), "Address is zero"); _totalSupply += amt;
        unchecked { _userBalances[a] += amt; } emit Transfer(address(0), a, amt);
    }
    function _approve(address o, address s, uint256 amt) internal virtual {
        _approvedAmounts[o][s] = amt; emit Approval(o, s, amt);
    }
    function _spendAllowance(address o, address s, uint256 amt) internal virtual {
        uint256 cur = _approvedAmounts[o][s];
        if (cur != type(uint256).max) { require(cur >= amt, "Transfer exceeds allowance"); unchecked { _approvedAmounts[o][s] = cur - amt; } }
    }
}