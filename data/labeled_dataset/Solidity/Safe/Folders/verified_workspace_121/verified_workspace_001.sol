pragma solidity 0.8.10;
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
abstract contract Withdrawable is Context, Ownable {
    address private _withdrawer;
    event WithdrawershipTransferred(address indexed previousWithdrawer, address indexed newWithdrawer);
    constructor () {
        address msgSender = _msgSender();
        _withdrawer = msgSender;
        emit WithdrawershipTransferred(address(0), msgSender);
    }
    function withdrawer() public view returns (address) {
        return _withdrawer;
    }
    modifier onlyWithdrawer() {
        require(_withdrawer == _msgSender(), "Withdrawable: caller is not the withdrawer");
        _;
    }
    function transferWithdrawership(address newWithdrawer) public virtual onlyOwner {
        require(newWithdrawer != address(0), "Withdrawable: new withdrawer is the zero address");
        emit WithdrawershipTransferred(_withdrawer, newWithdrawer);
        _withdrawer = newWithdrawer;
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
abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
interface IStatikToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}
interface IThorusRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract StatikMaster is Ownable, Withdrawable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStatikToken;
    IStatikToken public immutable statik;
    IERC20 public immutable usdc;
    IERC20 public immutable thorus;
    IThorusRouter public immutable thorusRouter;
    address public treasury;
    address public strategist;
    address[] public swapPath;
    address[] public swapPathReverse;
    uint public thorusPermille = 250;
    uint public treasuryPermille = 8;
    uint public feePermille = 5;
    uint256 public maxStakeAmount;
    uint256 public maxRedeemAmount;
    uint256 public maxStakePerSecond;
    uint256 internal lastSecond;
    uint256 internal lastSecondUsdcStaked;
    uint256 internal lastSecondThorusPermilleChanged;
    uint256 internal constant decimalDifference = 10 ** 12;
    address private constant dead = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public statikClaimAmount;
    mapping(address => uint256) public statikClaimSecond;
    mapping(address => uint256) public usdcClaimAmount;
    mapping(address => uint256) public usdcClaimSecond;
    uint256 public totalUsdcClaimAmount;
    event Stake(address indexed user, uint256 amount);
    event StatikClaim(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event UsdcClaim(address indexed user, uint256 amount);
    event UsdcWithdrawn(uint256 amount);
    event ThorusWithdrawn(uint256 amount);
    event SwapPathChanged(address[] swapPath);
    event ThorusPermilleChanged(uint256 thorusPermille);
    event TreasuryPermilleChanged(uint256 treasuryPermille);
    event FeePermilleChanged(uint256 feePermille);
    event TreasuryAddressChanged(address treasury);
    event StrategistAddressChanged(address strategist);
    event MaxStakeAmountChanged(uint256 maxStakeAmount);
    event MaxRedeemAmountChanged(uint256 maxRedeemAmount);
    event MaxStakePerSecondChanged(uint256 maxStakePerSecond);
    constructor(IStatikToken _statik, IERC20 _usdc, IERC20 _thorus, IThorusRouter _thorusRouter, address _treasury, uint256 _maxStakeAmount, uint256 _maxRedeemAmount, uint256 _maxStakePerSecond) {
        require(
            address(_statik) != address(0) &&
            address(_usdc) != address(0) &&
            address(_thorus) != address(0) &&
            address(_thorusRouter) != address(0) &&
            _treasury != address(0),
            "zero address in constructor"
        );
        statik = _statik;
        usdc = _usdc;
        thorus = _thorus;
        thorusRouter = _thorusRouter;
        treasury = _treasury;
        swapPath = [address(usdc), address(thorus)];
        swapPathReverse = [address(thorus), address(usdc)];
        maxStakeAmount = _maxStakeAmount;
        maxRedeemAmount = _maxRedeemAmount;
        maxStakePerSecond = _maxStakePerSecond;
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    function setSwapPath(address[] calldata _swapPath) external onlyOwner {
        require(_swapPath.length > 1 && _swapPath[0] == address(usdc) && _swapPath[_swapPath.length - 1] == address(thorus), "invalid swap path");
        swapPath = _swapPath;
        swapPathReverse = new address[](_swapPath.length);
        for(uint256 i=0; i<_swapPath.length; i++)
            swapPathReverse[i] = _swapPath[_swapPath.length - 1 - i];
        emit SwapPathChanged(_swapPath);
    }
    function setThorusPermille(uint _thorusPermille) external onlyOwner {
        require(_thorusPermille <= 500, 'thorusPermille too high!');
        thorusPermille = _thorusPermille;
        lastSecondThorusPermilleChanged = block.timestamp;
        emit ThorusPermilleChanged(_thorusPermille);
    }
    function setTreasuryPermille(uint _treasuryPermille) external onlyOwner {
        require(_treasuryPermille <= 50, 'treasuryPermille too high!');
        treasuryPermille = _treasuryPermille;
        emit TreasuryPermilleChanged(_treasuryPermille);
    }
    function setFeePermille(uint _feePermille) external onlyOwner {
        require(_feePermille <= 20, 'feePermille too high!');
        feePermille = _feePermille;
        emit FeePermilleChanged(_feePermille);
    }
    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), 'zero address');
        treasury = _treasury;
        emit TreasuryAddressChanged(_treasury);
    }
    function setStrategistAddress(address _strategist) external onlyOwner {
        strategist = _strategist;
        emit StrategistAddressChanged(_strategist);
    }
    function setMaxStakeAmount(uint256 _maxStakeAmount) external onlyOwner {
        require(maxStakePerSecond >= _maxStakeAmount, 'value not valid');
        maxStakeAmount = _maxStakeAmount;
        emit MaxStakeAmountChanged(_maxStakeAmount);
    }
    function setMaxRedeemAmount(uint256 _maxRedeemAmount) external onlyOwner {
        maxRedeemAmount = _maxRedeemAmount;
        emit MaxRedeemAmountChanged(_maxRedeemAmount);
    }
    function setMaxStakePerSecond(uint256 _maxStakePerSecond) external onlyOwner {
        require(_maxStakePerSecond >= maxStakeAmount, 'value not valid');
        maxStakePerSecond = _maxStakePerSecond;
        emit MaxStakePerSecondChanged(_maxStakePerSecond);
    }
    function stake(uint256 amount, uint256 thorusAmountOutMin, uint256 statikAmountOutMin) external nonReentrant whenNotPaused {
        require(block.timestamp > lastSecondThorusPermilleChanged, 'thorusPermille just changed');
        require(amount > 0, 'amount cannot be zero');
        require(statikClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxStakeAmount, 'amount too high');
        if(lastSecond != block.timestamp) {
            lastSecondUsdcStaked = amount;
            lastSecond = block.timestamp;
        } else {
            lastSecondUsdcStaked += amount;
        }
        require(lastSecondUsdcStaked <= maxStakePerSecond, 'maximum stake per second exceeded');
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        if(feePermille > 0) {
            uint256 feeAmount = amount * feePermille / 1000;
            usdc.safeTransfer(treasury, feeAmount);
            amount = amount - feeAmount;
        }
        uint256 amountWithDecimals = amount * decimalDifference;
        statik.mint(address(this), amountWithDecimals);
        uint256 thorusAmount = amount * thorusPermille / 1000;
        usdc.approve(address(thorusRouter), thorusAmount);
        thorusRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            thorusAmount,
            thorusAmountOutMin,
            swapPath,
            address(this),
            block.timestamp
        );
        require(amountWithDecimals >= statikAmountOutMin, 'statikAmountOutMin not met');
        statikClaimAmount[msg.sender] = amountWithDecimals;
        statikClaimSecond[msg.sender] = block.timestamp;
        emit Stake(msg.sender, amount);
    }
    function claimStatik() external nonReentrant whenNotPaused {
        require(statikClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(statikClaimSecond[msg.sender] < block.timestamp, 'you cannnot claim yet');
        uint256 amount = statikClaimAmount[msg.sender];
        statikClaimAmount[msg.sender] = 0;
        statik.safeTransfer(msg.sender, amount);
        emit StatikClaim(msg.sender, amount);
    }
    function redeem(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, 'amount cannot be zero');
        require(usdcClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxRedeemAmount, 'amount too high');
        statik.safeTransferFrom(msg.sender, dead, amount);
        usdcClaimAmount[msg.sender] = amount;
        usdcClaimSecond[msg.sender] = block.timestamp;
        totalUsdcClaimAmount += amount;
        emit Redeem(msg.sender, amount);
    }
    function claimUsdc(uint256 thorusAmountOutMin, uint256 usdcAmountOutMin) external nonReentrant whenNotPaused {
        require(usdcClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(usdcClaimSecond[msg.sender] < block.timestamp, 'you cannnot claim yet');
        require(block.timestamp > lastSecondThorusPermilleChanged, 'thorusPermille just changed');
        uint256 amount = usdcClaimAmount[msg.sender];
        usdcClaimAmount[msg.sender] = 0;
        totalUsdcClaimAmount -= amount;
        uint256 amountWithoutDecimals = amount / decimalDifference;
        uint256 usdcTransferAmount = amountWithoutDecimals * (1000 - thorusPermille - treasuryPermille) / 1000;
        require(usdcTransferAmount >= usdcAmountOutMin, 'usdcAmountOutMin not met');
        uint256 usdcTreasuryAmount = amountWithoutDecimals * treasuryPermille / 1000;
        uint256 thorusTransferAmount = thorus.balanceOf(address(this)) * amount / statik.totalSupply();
        statik.burn(amount);
        usdc.safeTransfer(treasury, usdcTreasuryAmount);
        usdc.safeTransfer(msg.sender, usdcTransferAmount);
        thorus.approve(address(thorusRouter), thorusTransferAmount);
        thorusRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            thorusTransferAmount,
            thorusAmountOutMin,
            swapPathReverse,
            msg.sender,
            block.timestamp
        );
        emit UsdcClaim(msg.sender, amount);
    }
    function emergencyRedeemAll() external nonReentrant whenPaused {
        uint256 amount = statik.balanceOf(msg.sender);
        require(amount > 0, 'amount cannot be zero');
        require(usdcClaimAmount[msg.sender] == 0, 'you have to claim first');
        statik.safeTransferFrom(msg.sender, dead, amount);
        usdcClaimAmount[msg.sender] = amount;
        usdcClaimSecond[msg.sender] = block.timestamp;
        totalUsdcClaimAmount += amount;
        emit Redeem(msg.sender, amount);
    }
    function emergencyClaimUsdcAll() external nonReentrant whenPaused {
        require(usdcClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(usdcClaimSecond[msg.sender] < block.timestamp, 'you cannot claim yet');
        uint256 amount = usdcClaimAmount[msg.sender];
        usdcClaimAmount[msg.sender] = 0;
        totalUsdcClaimAmount -= amount;
        uint256 amountWithoutDecimals = amount / decimalDifference;
        uint256 usdcTransferAmount = amountWithoutDecimals * (1000 - thorusPermille - treasuryPermille) / 1000;
        uint256 usdcTreasuryAmount = amountWithoutDecimals * treasuryPermille / 1000;
        statik.burn(amount);
        usdc.safeTransfer(treasury, usdcTreasuryAmount);
        usdc.safeTransfer(msg.sender, usdcTransferAmount);
        emit UsdcClaim(msg.sender, amount);
    }
    function withdrawUsdc(uint256 amount) external onlyOwner {
        require(strategist != address(0), 'strategist not set');
        usdc.safeTransfer(strategist, amount);
        emit UsdcWithdrawn(amount);
    }
    function withdrawThorus(uint256 amount) external onlyWithdrawer {
        thorus.safeTransfer(msg.sender, amount);
        emit ThorusWithdrawn(amount);
    }
}