pragma solidity ^0.4.21;
import '../math/SafeMath.sol';
import './IERC20Token.sol';
contract LockedTokens is SafeMath {
    struct Tokens {
        uint256 amount;
        uint256 lockEndTime;
        bool released;
    }
    event TokensUnlocked(address _to, uint256 _value);
    IERC20Token public token;
    address public crowdsaleAddress;
    mapping(address => Tokens[]) public walletTokens;
    function LockedTokens(IERC20Token _token, address _crowdsaleAddress) public {
        token = _token;
        crowdsaleAddress = _crowdsaleAddress;
    }
    function addTokens(address _to, uint256 _amount, uint256 _lockEndTime) external {
        require(msg.sender == crowdsaleAddress);
        walletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
    }
    function releaseTokens() public {
        require(walletTokens[msg.sender].length > 0);
        for(uint256 i = 0; i < walletTokens[msg.sender].length; i++) {
            if(!walletTokens[msg.sender][i].released && now >= walletTokens[msg.sender][i].lockEndTime) {
                walletTokens[msg.sender][i].released = true;
                token.transfer(msg.sender, walletTokens[msg.sender][i].amount);
                TokensUnlocked(msg.sender, walletTokens[msg.sender][i].amount);
            }
        }
    }
}