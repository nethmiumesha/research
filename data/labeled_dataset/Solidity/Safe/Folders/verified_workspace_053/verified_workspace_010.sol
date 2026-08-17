pragma solidity 0.6.12;
import "./Owned.sol";
import "./Utils.sol";
import "./TokenHandler.sol";
import "./interfaces/ITokenHolder.sol";
import "../token/interfaces/IERC20Token.sol";
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override
        ownerOnly
        validAddress(address(_token))
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}