pragma solidity ^0.8.0;
import "../WrappedPosition.sol";
import "./TestERC20.sol";
contract TestWrappedPosition is WrappedPosition {
    uint256 public underlyingUnitValue = 100;
    constructor(IERC20 _token)
        WrappedPosition(_token, "ELement Finance", "TestWrappedPosition")
    {}
    function _deposit() internal override returns (uint256, uint256) {
        uint256 deposited = token.balanceOf(address(this));
        TestERC20(address(token)).setBalance(address(this), 0);
        return (deposited / underlyingUnitValue, deposited);
    }
    function _withdraw(
        uint256 amount,
        address destination,
        uint256
    ) internal override returns (uint256) {
        TestERC20(address(token)).uncheckedTransfer(
            destination,
            amount * underlyingUnitValue
        );
        return (amount * underlyingUnitValue);
    }
    function setSharesToUnderlying(uint256 _value) external {
        underlyingUnitValue = _value;
    }
    function _underlying(uint256 _shares)
        internal
        override
        view
        returns (uint256)
    {
        return _shares * underlyingUnitValue;
    }
}