pragma solidity 0.7.5;
interface IOwnable {
  function owner() external view returns (address);
  function renounceOwnership() external;
  function transferOwnership( address newOwner_ ) external;
}
contract Ownable is IOwnable {
  address internal _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }
  function owner() public view override returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }
  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }
  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}
interface IStaking {
    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_
    ) external;
    function stakeOLYWithPermit (
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;
    function unstakeOLYWithPermit (
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;
    function stakeOLY( uint amountToStake_ ) external returns ( bool );
    function unstakeOLY( uint amountToWithdraw_ ) external returns ( bool );
    function distributeOLYProfits() external;
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);
        _addr[0] = '0';
        _addr[1] = 'x';
        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_addr);
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface ITreasury {
  function getBondingCalculator() external returns ( address );
  function payDebt( address depositor_ ) external returns ( bool );
  function getTimelockEndBlock() external returns ( uint );
  function getManagedToken() external returns ( address );
  function getDebtAmountDue() external returns ( uint );
  function incurDebt( address principleToken_, uint principieTokenAmountDeposited_ ) external returns ( bool );
}
interface IOHMandsOHM {
    function rebase(uint256 ohmProfit)
        external
        returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
contract OlympusStaking is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  uint256 public epochLengthInBlocks;
  address public ohm;
  address public sOHM;
  uint256 public ohmToDistributeNextEpoch;
  uint256 nextEpochBlock;
  bool isInitialized;
  modifier notInitialized() {
    require( !isInitialized );
    _;
  }
  function initialize(
        address ohmTokenAddress_,
        address sOHM_,
        uint8 epochLengthInBlocks_
    ) external onlyOwner() notInitialized() {
        ohm = ohmTokenAddress_;
        sOHM = sOHM_;
        epochLengthInBlocks = epochLengthInBlocks_;
        isInitialized = true;
    }
    function setEpochLengthintBlock( uint256 newEpochLengthInBlocks_ ) external onlyOwner() {
        epochLengthInBlocks = newEpochLengthInBlocks_;
    }
    function _distributeOHMProfits() internal {
        if( nextEpochBlock <= block.number ) {
            IOHMandsOHM(sOHM).rebase(ohmToDistributeNextEpoch);
            uint256 _ohmBalance = IOHMandsOHM(ohm).balanceOf(address(this));
            uint256 _sohmSupply = IOHMandsOHM(sOHM).circulatingSupply();
            ohmToDistributeNextEpoch = _ohmBalance.sub(_sohmSupply);
            nextEpochBlock = nextEpochBlock.add( epochLengthInBlocks );
        }
    }
    function _stakeOHM( uint256 amountToStake_ ) internal {
        _distributeOHMProfits();
        IERC20(ohm).safeTransferFrom(
            msg.sender,
            address(this),
            amountToStake_
        );
        IERC20(sOHM).safeTransfer(msg.sender, amountToStake_);
    }
    function stakeOHMWithPermit (
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        IOHMandsOHM(ohm).permit(
            msg.sender,
            address(this),
            amountToStake_,
            deadline_,
            v_,
            r_,
            s_
        );
        _stakeOHM( amountToStake_ );
    }
    function stakeOHM( uint amountToStake_ ) external returns ( bool ) {
      _stakeOHM( amountToStake_ );
      return true;
    }
    function _unstakeOHM( uint256 amountToUnstake_ ) internal {
      _distributeOHMProfits();
      IERC20(sOHM).safeTransferFrom(
            msg.sender,
            address(this),
            amountToUnstake_
        );
      IERC20(ohm).safeTransfer(msg.sender, amountToUnstake_);
    }
    function unstakeOHMWithPermit (
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        IOHMandsOHM(sOHM).permit(
            msg.sender,
            address(this),
            amountToWithdraw_,
            deadline_,
            v_,
            r_,
            s_
        );
        _unstakeOHM( amountToWithdraw_ );
    }
    function unstakeOHM( uint amountToWithdraw_ ) external returns ( bool ) {
        _unstakeOHM( amountToWithdraw_ );
        return true;
    }
}