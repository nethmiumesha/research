pragma solidity ^0.8.0;
import "../interfaces/IBEP20.sol";
import "./Address.sol";
library SafeBEP20 {
	using Address for address;
	function safeTransfer(
		IBEP20 token,
		address to,
		uint value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}
	function safeTransferFrom(
		IBEP20 token,
		address from,
		address to,
		uint value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}
	function safeApprove(
		IBEP20 token,
		address spender,
		uint value
	) internal {
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeBEP20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}
	function safeIncreaseAllowance(
		IBEP20 token,
		address spender,
		uint value
	) internal {
		uint newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}
	function safeDecreaseAllowance(
		IBEP20 token,
		address spender,
		uint value
	) internal {
		unchecked {
			uint oldAllowance = token.allowance(address(this), spender);
			require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
			uint newAllowance = oldAllowance - value;
			_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
		}
	}
	function _callOptionalReturn(IBEP20 token, bytes memory data) private {
		bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
		if (returndata.length > 0) {
			require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
		}
	}
}