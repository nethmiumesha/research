pragma solidity ^0.4.24;
import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "./PropsTimeBasedTransfers.sol";
import "./ERC865Token.sol";
import "./PropsRewards.sol";
contract PropsToken is Initializable, ERC20Detailed, ERC865Token, PropsTimeBasedTransfers, PropsRewards {
  function initialize(
    address _holder,
    address _controller,
    uint256 _minSecondsBetweenDays,
    uint256 _rewardsStartTimestamp
  )
    public
    initializer
  {
    uint8 decimals = 18;
    uint256 totalSupply = 0.6 * 1e9 * (10 ** uint256(decimals));
    ERC20Detailed.initialize("Props Token", "PROPS", decimals);
    PropsRewards.initializePostRewardsUpgrade1(_controller, _minSecondsBetweenDays, _rewardsStartTimestamp);
    _mint(_holder, totalSupply);
  }
}