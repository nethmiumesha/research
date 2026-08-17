pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
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
pragma solidity ^0.8.0;
pragma solidity ^0.8.0;
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
pragma solidity ^0.8.0;
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
pragma solidity 0.8.9;
interface IByalanIsland {
    function izlude() external view returns (address);
}
pragma solidity 0.8.9;
interface ISailor {
    function MAX_FEE() external view returns (uint256);
    function totalFee() external view returns (uint256);
    function callFee() external view returns (uint256);
    function kswFee() external view returns (uint256);
}
pragma solidity 0.8.9;
interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfMasterChef() external view returns (uint256);
    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);
    function harvest() external;
    function retireStrategy() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}
pragma solidity 0.8.9;
interface IFeeKafra {
    function MAX_FEE() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
    function treasuryFeeWithdraw() external view returns (uint256);
    function kswFeeWithdraw() external view returns (uint256);
    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);
    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;
}
pragma solidity 0.8.9;
interface IIzludeV2 {
    function totalSupply() external view returns (uint256);
    function prontera() external view returns (address);
    function want() external view returns (IERC20);
    function deposit(address user, uint256 amount) external returns (uint256 jellopy);
    function withdraw(address user, uint256 jellopy) external returns (uint256);
    function balance() external view returns (uint256);
    function byalan() external view returns (IByalan);
    function feeKafra() external view returns (address);
    function allocKafra() external view returns (address);
    function calculateWithdrawFee(uint256 amount, address user) external view returns (uint256);
}
pragma solidity 0.8.9;
interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);
    function limitAllocation() external view returns (uint16);
    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}
pragma solidity 0.8.9;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
pragma solidity 0.8.9;
contract IzludeV2 is IIzludeV2, Ownable {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_WITHDRAW_FEE = 1000;
    address public immutable override prontera;
    IByalan public override byalan;
    IERC20 public immutable override want;
    uint256 public override totalSupply;
    address public override feeKafra;
    address public override allocKafra;
    address public tva;
    event UpgradeStrategy(address implementation);
    event SetFeeKafra(address kafra);
    event SetAllocKafra(address kafra);
    event SetTVA(address tva);
    constructor(
        address _prontera,
        IByalan _byalan,
        address _tva
    ) {
        prontera = _prontera;
        byalan = _byalan;
        want = IERC20(byalan.want());
        tva = _tva;
    }
    modifier onlyProntera() {
        require(msg.sender == prontera, "!prontera");
        _;
    }
    function setFeeKafra(address _feeKafra) external onlyOwner {
        feeKafra = _feeKafra;
        emit SetFeeKafra(_feeKafra);
    }
    function setAllocKafra(address _allocKafra) external onlyOwner {
        allocKafra = _allocKafra;
        emit SetAllocKafra(_allocKafra);
    }
    function setTva(address _tva) external {
        require(tva == msg.sender, "!TVA");
        tva = _tva;
        emit SetTVA(_tva);
    }
    function balance() public view override returns (uint256) {
        return want.balanceOf(address(this)) + byalan.balanceOf();
    }
    function calculateWithdrawFee(uint256 amount, address user) public view override returns (uint256) {
        if (feeKafra == address(0)) {
            return 0;
        }
        return Math.min(IFeeKafra(feeKafra).calculateWithdrawFee(amount, user), _calculateMaxWithdrawFee(amount));
    }
    function _calculateMaxWithdrawFee(uint256 amount) private pure returns (uint256) {
        return (amount * MAX_WITHDRAW_FEE) / 10000;
    }
    function checkAllocation(uint256 amount, address user) private view {
        require(
            allocKafra == address(0) ||
                IAllocKafra(allocKafra).canAllocate(amount, byalan.balanceOf(), byalan.balanceOfMasterChef(), user),
            "capacity limit reached"
        );
    }
    function deposit(address user, uint256 amount) external override onlyProntera returns (uint256 jellopy) {
        byalan.beforeDeposit();
        uint256 poolBefore = balance();
        want.safeTransferFrom(msg.sender, address(this), amount);
        earn();
        checkAllocation(amount, user);
        if (totalSupply == 0) {
            jellopy = amount;
        } else {
            jellopy = (amount * totalSupply) / poolBefore;
        }
        totalSupply += jellopy;
    }
    function earn() public {
        want.safeTransfer(address(byalan), want.balanceOf(address(this)));
        byalan.deposit();
    }
    function _withdraw(address user, uint256 jellopy) private returns (uint256) {
        uint256 r = (balance() * jellopy) / totalSupply;
        totalSupply -= jellopy;
        uint256 b = want.balanceOf(address(this));
        if (b < r) {
            uint256 amount = r - b;
            byalan.withdraw(amount);
            uint256 _after = want.balanceOf(address(this));
            uint256 diff = _after - b;
            if (diff < amount) {
                r = b + diff;
            }
        }
        uint256 fee = calculateWithdrawFee(r, user);
        if (fee > 0) {
            r -= fee;
            want.safeTransfer(address(feeKafra), fee);
            IFeeKafra(feeKafra).distributeWithdrawFee(want, user);
        }
        want.safeTransfer(msg.sender, r);
        return r;
    }
    function withdraw(address user, uint256 jellopy) external override onlyProntera returns (uint256) {
        return _withdraw(user, jellopy);
    }
    function upgradeStrategy(address implementation) external {
        require(tva == msg.sender, "!TVA");
        require(address(this) == IByalan(implementation).izlude(), "invalid byalan");
        require(want == IERC20(byalan.want()), "invalid byalan want");
        byalan.retireStrategy();
        byalan = IByalan(implementation);
        earn();
        emit UpgradeStrategy(implementation);
    }
    function inCaseTokensGetStuck(address token) external onlyOwner {
        require(token != address(want), "!want");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}