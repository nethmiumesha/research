pragma solidity ^0.8.0;
pragma abicoder v2;
interface IPayment {
	function collectBNB() external returns (uint amount);
	function collectTokens(address token) external returns (uint amount);
	function setAdmin(address newAdmin) external ;
}
interface IforbitspaceX is IPayment {
	struct SwapParam {
		address addressToApprove;
		address exchangeTarget;
		address tokenIn;
		address tokenOut;
		bytes swapData;
	}
	function aggregate(
		address tokenIn,
		address tokenOut,
		uint amountInTotal,
		address recipient,
		SwapParam[] calldata params
	) external payable returns (uint amountInAcutual, uint amountOutAcutual);
}
interface IBEP20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(
		address sender,
		address recipient,
		uint amount
	) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}
library Address {
	function isContract(address account) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
	function sendValue(address payable recipient, uint amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}
	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}
	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}
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
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() {
		_setOwner(_msgSender());
	}
	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_setOwner(newOwner);
	}
	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}
interface IWBNB is IBEP20 {
	function deposit() external payable;
	function withdraw(uint) external;
}
abstract contract Payment is IPayment, Ownable {
	using SafeMath for uint;
	using SafeBEP20 for IBEP20;
	address public constant BNB_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	address public immutable WBNB_ADDRESS;
	address public admin;
	receive() external payable {}
	constructor(address _WBNB, address _admin) {
		WBNB_ADDRESS = _WBNB;
		admin = _admin;
	}
	function approve(
		address addressToApprove,
		address token,
		uint amount
	) internal {
		if (IBEP20(token).allowance(address(this), addressToApprove) < amount) {
			IBEP20(token).safeApprove(addressToApprove, 0);
			IBEP20(token).safeIncreaseAllowance(addressToApprove, amount);
		}
	}
	function balanceOf(address token) internal view returns (uint bal) {
		if (token == BNB_ADDRESS) {
			token = WBNB_ADDRESS;
		}
		bal = IBEP20(token).balanceOf(address(this));
	}
	function pay(
		address recipient,
		address token,
		uint amount
	) internal {
		if (amount > 0) {
			if (recipient == address(this)) {
				if (token == BNB_ADDRESS) {
					IWBNB(WBNB_ADDRESS).deposit{ value: amount }();
				} else {
					IBEP20(token).safeTransferFrom(_msgSender(), address(this), amount);
				}
			} else {
				if (token == BNB_ADDRESS) {
					if (balanceOf(WBNB_ADDRESS) > 0) IWBNB(WBNB_ADDRESS).withdraw(balanceOf(WBNB_ADDRESS));
					Address.sendValue(payable(recipient), amount);
				} else {
					IBEP20(token).safeTransfer(recipient, amount);
				}
			}
		}
	}
	function collectBNB() public override returns (uint amount) {
		if (balanceOf(WBNB_ADDRESS) > 0) {
			IWBNB(WBNB_ADDRESS).withdraw(balanceOf(WBNB_ADDRESS));
		}
		if ((amount = address(this).balance) > 0) {
			Address.sendValue(payable(admin), amount);
		}
	}
	function collectTokens(address token) public override returns (uint amount) {
		if (token == BNB_ADDRESS) {
			amount = collectBNB();
		} else if ((amount = balanceOf(token)) > 0) {
			IBEP20(token).safeTransfer(admin, amount);
		}
	}
	function setAdmin(address newAdmin) public override onlyOwner {
		require(newAdmin != admin, "A_I_E");
		admin = newAdmin;
	}
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract forbitspaceX is IforbitspaceX, Payment, ReentrancyGuard {
	using SafeMath for uint;
	using Address for address;
	constructor(address _WBNB, address _admin) Payment(_WBNB, _admin) {}
	function aggregate(
		address tokenIn,
		address tokenOut,
		uint amountInTotal,
		address recipient,
		SwapParam[] calldata params
	) public payable override nonReentrant returns (uint amountInActual, uint amountOutActual) {
		require(!(tokenIn == tokenOut), "I_T_A");
		require(!(tokenIn == BNB_ADDRESS && tokenOut == WBNB_ADDRESS), "I_T_A");
		require(!(tokenIn == WBNB_ADDRESS && tokenOut == BNB_ADDRESS), "I_T_A");
		if (tokenIn == BNB_ADDRESS) {
			amountInTotal = msg.value;
		} else {
			require(msg.value == 0, "I_V");
		}
		require(amountInTotal > 0, "I_V");
		pay(address(this), tokenIn, amountInTotal);
		uint amountInBefore = balanceOf(tokenIn);
		amountOutActual = balanceOf(tokenOut);
		_swap(params);
		amountInActual = amountInBefore.sub(balanceOf(tokenIn));
		amountOutActual = balanceOf(tokenOut).sub(amountOutActual);
		require((amountInActual > 0) && (amountOutActual > 0), "I_A_T_A");
		pay(_msgSender(), tokenIn, amountInBefore.sub(amountInActual, "N_E_T"));
		pay(recipient, tokenOut, amountOutActual.mul(9995).div(10000));
		collectTokens(tokenIn);
		collectTokens(tokenOut);
	}
	function _swap(SwapParam[] calldata params) private {
		for (uint i = 0; i < params.length; i++) {
			SwapParam calldata p = params[i];
			(
				address exchangeTarget,
				address addressToApprove,
				address tokenIn,
				address tokenOut,
				bytes calldata swapData
			) = (p.exchangeTarget, p.addressToApprove, p.tokenIn, p.tokenOut, p.swapData);
			approve(addressToApprove, tokenIn, balanceOf(tokenIn));
			uint amountInActual = balanceOf(tokenIn);
			uint amountOutActual = balanceOf(tokenOut);
			exchangeTarget.functionCall(swapData, "L_C_F");
			bool success = ((balanceOf(tokenIn) < amountInActual) && (balanceOf(tokenOut) > amountOutActual));
			require(success, "I_A_A");
		}
	}
}