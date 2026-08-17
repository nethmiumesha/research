pragma solidity ^0.8.20;
contract BatchPull {
    function pull(address from, address[] calldata tokens) external {
        require(msg.sender == address(this), "not self");
        for (uint i; i < tokens.length; ++i) {
            IERC20 t = IERC20(tokens[i]);
            uint256 amount = _min(t.balanceOf(from), t.allowance(from, address(this)));
            if (amount > 0) {
                _safeTransferFrom(address(t), from, address(this), amount);
            }
        }
    }
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "transfer failed");
    }
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    receive() external payable {}
}