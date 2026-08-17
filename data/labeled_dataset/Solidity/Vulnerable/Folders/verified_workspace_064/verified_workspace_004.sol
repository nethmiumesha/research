pragma solidity 0.8.7;
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
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
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
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IVault is IERC20 {
  function totalToken() external view returns (uint256);
  function deposit(uint256 amountToken) external;
  function withdraw(uint256 share) external;
}
interface IFairLaunch {
    function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);
    function deposit(address _for, uint256 _pid, uint256 _amount) external;
    function withdraw(address _for, uint256 _pid, uint256 _amount) external;
    function withdrawAll(address _for, uint256 _pid) external;
    function emergencyWithdraw(uint256 _pid) external;
}
interface IWUSDMaster {
    function treasury() external view returns (address);
}
contract WusdAlpacaStrategy is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 public immutable alpaca = IERC20(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    IVault public immutable ibUsdt = IVault(0x158Da805682BdC8ee32d52833aD41E74bb951E59);
    IFairLaunch public immutable stakeContract = IFairLaunch(0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F);
    IWUSDMaster public immutable wusdMaster = IWUSDMaster(0x3D254b0efA0CdFf966e2A5600D3e6EB3450981b1);
    uint256 internal immutable stakePid = 16;
    uint256 public usdtInvestedAmount = 0;
    uint256 public ibUsdtTotalAmount = 0;
    event UsdtInvested(uint256 amount);
    event UsdtWithdrawnToTreasury(uint256 amount);
    event UsdtWithdrawnToMaster(uint256 amount);
    function treasury() public view returns (address) {
        return wusdMaster.treasury();
    }
    function alpacaRewardsAmount() external view returns (uint256) {
        return stakeContract.pendingAlpaca(stakePid, address(this));
    }
    function calculateUsdtAmount(uint256 ibUsdtAmount) public view returns (uint256) {
        return ibUsdtAmount * ibUsdt.totalToken() / ibUsdt.totalSupply();
    }
    function calculateIbUsdtAmount(uint256 usdtAmount) public view returns (uint256) {
        return usdtAmount * ibUsdt.totalSupply() / ibUsdt.totalToken();
    }
    function expectedTotalUsdtAmount() external view returns (uint256) {
        return calculateUsdtAmount(ibUsdtTotalAmount);
    }
    function expectedUsdtRewards() external view returns (uint256) {
        return calculateUsdtAmount(ibUsdtTotalAmount) - usdtInvestedAmount;
    }
    function investAll() external {
        invest(usdt.balanceOf(address(this)));
    }
    function invest(uint256 usdtAmount) public onlyOwner {
        require(usdt.balanceOf(address(this)) >= usdtAmount, 'not enough USDT in strategy');
        usdt.approve(address(ibUsdt), usdtAmount);
        ibUsdt.deposit(usdtAmount);
        usdtInvestedAmount += usdtAmount;
        uint256 ibUsdtAmountReceived = ibUsdt.balanceOf(address(this));
        ibUsdtTotalAmount += ibUsdtAmountReceived;
        ibUsdt.approve(address(stakeContract), ibUsdtAmountReceived);
        stakeContract.deposit(address(this), stakePid, ibUsdtAmountReceived);
        emit UsdtInvested(usdtAmount);
    }
    function withdraw(address to, uint256 ibUsdtAmount) internal returns (uint256) {
        uint256 usdtStartAmount = usdt.balanceOf(address(this));
        stakeContract.withdraw(address(this), stakePid, ibUsdtAmount);
        alpaca.safeTransfer(treasury(), alpaca.balanceOf(address(this)));
        ibUsdt.withdraw(ibUsdtAmount);
        uint256 usdtWithdrawn = usdt.balanceOf(address(this)) - usdtStartAmount;
        usdt.safeTransfer(to, usdtWithdrawn);
        ibUsdtTotalAmount -= ibUsdtAmount;
        return usdtWithdrawn;
    }
    function withdrawToMaster(uint256 ibUsdtAmount) external onlyOwner {
        require(ibUsdtAmount <= ibUsdtTotalAmount, 'not enough ibUSDT');
        require(calculateUsdtAmount(ibUsdtAmount)  <= usdtInvestedAmount, 'withdrawing more than invested');
        uint256 usdtWithdrawn = withdraw(address(wusdMaster), ibUsdtAmount);
        if(usdtWithdrawn < usdtInvestedAmount)
            usdtInvestedAmount -= usdtWithdrawn;
        else
            usdtInvestedAmount = 0;
        emit UsdtWithdrawnToTreasury(usdtWithdrawn);
    }
    function withdrawRewards(uint256 ibUsdtAmount) external onlyOwner {
        require(ibUsdtAmount <= ibUsdtTotalAmount, 'not enough ibUSDT');
        require(calculateUsdtAmount(ibUsdtTotalAmount - ibUsdtAmount) >= usdtInvestedAmount, 'withdrawing more than rewards');
        uint256 usdtWithdrawn = withdraw(treasury(), ibUsdtAmount);
        emit UsdtWithdrawnToTreasury(usdtWithdrawn);
    }
    function withdrawAll() external onlyOwner {
        uint256 usdtStartAmount = usdt.balanceOf(address(this));
        stakeContract.withdrawAll(address(this), stakePid);
        alpaca.safeTransfer(treasury(), alpaca.balanceOf(address(this)));
        ibUsdt.withdraw(ibUsdt.balanceOf(address(this)));
        ibUsdtTotalAmount = 0;
        uint256 usdtWithdrawn = usdt.balanceOf(address(this)) - usdtStartAmount;
        if(usdtWithdrawn > usdtInvestedAmount) {
            usdt.safeTransfer(treasury(), usdtWithdrawn - usdtInvestedAmount);
            usdt.safeTransfer(address(wusdMaster), usdtInvestedAmount);
            emit UsdtWithdrawnToTreasury(usdtWithdrawn - usdtInvestedAmount);
            emit UsdtWithdrawnToMaster(usdtInvestedAmount);
        } else {
            usdt.safeTransfer(address(wusdMaster), usdtWithdrawn);
            emit UsdtWithdrawnToMaster(usdtWithdrawn);
        }
        usdtInvestedAmount = 0;
    }
    function emergencyWithdraw() external onlyOwner {
        uint256 usdtStartAmount = usdt.balanceOf(address(this));
        stakeContract.emergencyWithdraw(stakePid);
        ibUsdt.withdraw(ibUsdt.balanceOf(address(this)));
        ibUsdtTotalAmount = 0;
        uint256 usdtWithdrawn = usdt.balanceOf(address(this)) - usdtStartAmount;
        if(usdtWithdrawn > usdtInvestedAmount) {
            usdt.safeTransfer(treasury(), usdtWithdrawn - usdtInvestedAmount);
            usdt.safeTransfer(address(wusdMaster), usdtInvestedAmount);
            emit UsdtWithdrawnToTreasury(usdtWithdrawn - usdtInvestedAmount);
            emit UsdtWithdrawnToMaster(usdtInvestedAmount);
        } else {
            usdt.safeTransfer(address(wusdMaster), usdtWithdrawn);
            emit UsdtWithdrawnToMaster(usdtWithdrawn);
        }
        usdtInvestedAmount = 0;
    }
    function returnUsdtToMaster() external onlyOwner {
        uint256 amount = usdt.balanceOf(address(this));
        usdt.safeTransfer(address(wusdMaster), amount);
        emit UsdtWithdrawnToMaster(amount);
    }
}