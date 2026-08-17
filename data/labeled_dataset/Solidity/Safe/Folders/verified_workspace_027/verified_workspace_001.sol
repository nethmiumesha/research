pragma solidity 0.5.8;
contract OZStorage {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    uint256 private _guardCounter;
    function totalSupply() internal view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _investor) internal view returns(uint256) {
        return _balances[_investor];
    }
    function _allowance(address owner, address spender) internal view returns(uint256) {
        return _allowed[owner][spender];
    }
}