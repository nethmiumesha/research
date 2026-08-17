pragma solidity ^0.7.0;
import "../utils/SafeERC20.sol";
import "../interfaces/IERC20.sol";
contract FLFeeFaucet {
    using SafeERC20 for IERC20;
    function my2Wei(address _tokenAddr) public {
        IERC20(_tokenAddr).safeTransfer(msg.sender, 2);
    }
}