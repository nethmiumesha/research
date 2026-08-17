pragma solidity ^0.4.13;
import "./ERC20.sol";
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes extraData
    ) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData);
    }
    function() public payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}