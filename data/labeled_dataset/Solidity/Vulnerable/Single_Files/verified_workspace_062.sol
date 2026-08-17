pragma solidity ^0.8.27;
contract WOO {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(address recipient) {
        _name = "WOO";
        _symbol = "WOO";
        uint256 value = 1888782088 * 10 ** 18;
        _totalSupply += value;
        _balances[recipient] += value;
    }
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return 18; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
}