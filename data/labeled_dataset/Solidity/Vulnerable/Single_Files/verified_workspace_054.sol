pragma solidity ^0.8.0;
contract TetherToken {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    constructor(uint256 _amount) {
        totalSupply = _amount * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Bakiye yetersiz");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }
}