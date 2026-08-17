pragma solidity 0.5.11;
import "../../contracts/contracts/token/OUSD.sol";
contract OUSDHarness is OUSD {
	function Certora_maxSupply() external view returns (uint) { return MAX_SUPPLY; }
	function Certora_isNonRebasingAccount(address account) external returns (bool) { return _isNonRebasingAccount(account); }
	function init_state() external {
		rebasingCreditsPerToken = 1e18;
	}
	function _creditsPerToken(address _account)
		internal
		view
		returns (uint256)
	{
		return 1e18;
	}
}