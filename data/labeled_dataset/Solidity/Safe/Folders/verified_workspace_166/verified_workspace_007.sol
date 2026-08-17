pragma solidity 0.5.17;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./OwnerPausable.sol";
import "./SwapUtils.sol";
import "./MathUtils.sol";
import "./Allowlist.sol";
contract Swap is OwnerPausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;
    using SwapUtils for SwapUtils.Swap;
    SwapUtils.Swap public swapStorage;
    IAllowlist public allowlist;
    bool public isGuarded = true;
    mapping(address => uint8) private tokenIndexes;
    event TokenSwap(address indexed buyer, uint256 tokensSold,
        uint256 tokensBought, uint128 soldId, uint128 boughtId
    );
    event AddLiquidity(address indexed provider, uint256[] tokenAmounts,
        uint256[] fees, uint256 invariant, uint256 lpTokenSupply
    );
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(address indexed provider, uint256 lpTokenAmount,
        uint256 lpTokenSupply, uint256 boughtId, uint256 tokensBought
    );
    event RemoveLiquidityImbalance(address indexed provider,
        uint256[] tokenAmounts, uint256[] fees, uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 A, uint256 time);
    constructor(
        IERC20[] memory _pooledTokens, uint256[] memory precisions,
        string memory lpTokenName, string memory lpTokenSymbol, uint256 _A,
        uint256 _fee, uint256 _adminFee, uint256 _withdrawFee, IAllowlist _allowlist
    ) public OwnerPausable() ReentrancyGuard() {
        require(
            _pooledTokens.length > 1,
            "Pools must contain more than 1 token"
        );
        require(
            _pooledTokens.length <= 32,
            "Pools with over 32 tokens aren't supported"
        );
        require(
            _pooledTokens.length == precisions.length,
            "Each pooled token needs a specified precision"
        );
        for (uint8 i = 0; i < _pooledTokens.length; i++) {
            if (i > 0) {
                require(tokenIndexes[address(_pooledTokens[i])] == 0, "Pools cannot have duplicate tokens");
            }
            require(
                address(_pooledTokens[i]) != address(0),
                "The 0 address isn't an ERC-20"
            );
            require(
                precisions[i] <= 10 ** uint256(SwapUtils.getPoolPrecisionDecimals()),
                "Token precision can't be higher than the pool precision"
            );
            precisions[i] = (10 ** uint256(SwapUtils.getPoolPrecisionDecimals())).div(precisions[i]);
            tokenIndexes[address(_pooledTokens[i])] = i;
        }
        swapStorage = SwapUtils.Swap({
            lpToken: new LPToken(lpTokenName, lpTokenSymbol, SwapUtils.getPoolPrecisionDecimals()),
            pooledTokens: _pooledTokens,
            tokenPrecisionMultipliers: precisions,
            balances: new uint256[](_pooledTokens.length),
            initialA: _A.mul(SwapUtils.getAPrecision()),
            futureA: _A.mul(SwapUtils.getAPrecision()),
            initialATime: 0,
            futureATime: 0,
            swapFee: _fee,
            adminFee: _adminFee,
            defaultWithdrawFee: _withdrawFee
        });
        allowlist = _allowlist;
        require(allowlist.getPoolCap(address(0x0)) == uint256(0x54dd1e), "Allowlist check failed");
        isGuarded = true;
    }
    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, "Deadline not met");
        _;
    }
    function getA() external view returns (uint256) {
        return swapStorage.getA();
    }
    function getAPrecise() external view returns (uint256) {
        return swapStorage.getAPrecise();
    }
    function getToken(uint8 index) public view returns (IERC20) {
        require(index < swapStorage.pooledTokens.length, "Out of range");
        return swapStorage.pooledTokens[index];
    }
    function getTokenIndex(address tokenAddress) external view returns (uint8) {
        uint8 index = tokenIndexes[tokenAddress];
        require(address(getToken(index)) == tokenAddress, "Token does not exist");
        return index;
    }
    function getDepositTimestamp(address user) external view returns (uint256) {
        return swapStorage.getDepositTimestamp(user);
    }
    function getTokenBalance(uint8 index) external view returns (uint256) {
        require(index < swapStorage.pooledTokens.length, "Index out of range");
        return swapStorage.balances[index];
    }
    function getVirtualPrice() external view returns (uint256) {
        return swapStorage.getVirtualPrice();
    }
    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx
    ) external view returns(uint256) {
        return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external view returns(uint256) {
        return swapStorage.calculateTokenAmount(amounts, deposit);
    }
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory) {
        return swapStorage.calculateRemoveLiquidity(amount);
    }
    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount) {
        (availableTokenAmount, ) = swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
    }
    function calculateCurrentWithdrawFee(address user) external view returns (uint256) {
        return swapStorage.calculateCurrentWithdrawFee(user);
    }
    function getAdminBalance(uint256 index) external view returns (uint256) {
        return swapStorage.getAdminBalance(index);
    }
    function swap(
        uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline
    ) external nonReentrant onlyUnpaused deadlineCheck(deadline) {
        return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
    }
    function addLiquidity(uint256[] calldata amounts, uint256 minToMint, uint256 deadline)
        external nonReentrant onlyUnpaused deadlineCheck(deadline) {
        swapStorage.addLiquidity(amounts, minToMint);
        if (isGuarded) {
            require(
                allowlist.getAllowedAmount(address(this), msg.sender) >= swapStorage.lpToken.balanceOf(msg.sender),
                "Deposit limit reached"
            );
            require(
                allowlist.getPoolCap(address(this)) >= swapStorage.lpToken.totalSupply(),
                "Pool TVL cap reached"
            );
        }
    }
    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline)
        external nonReentrant deadlineCheck(deadline) {
        return swapStorage.removeLiquidity(amount, minAmounts);
    }
    function removeLiquidityOneToken(
        uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline
    ) external nonReentrant onlyUnpaused deadlineCheck(deadline) {
        return swapStorage.removeLiquidityOneToken(tokenAmount, tokenIndex, minAmount);
    }
    function removeLiquidityImbalance(
        uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline
    ) external nonReentrant onlyUnpaused deadlineCheck(deadline) {
        return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
    }
    function updateUserWithdrawFee(address recipient, uint256 transferAmount) external {
        require(msg.sender == address(swapStorage.lpToken), "Only token transfers can update withdraw fee");
        swapStorage.updateUserWithdrawFee(recipient, transferAmount);
    }
    function withdrawAdminFees() external onlyOwner {
        swapStorage.withdrawAdminFees(owner());
    }
    function setAdminFee(uint256 newAdminFee) external onlyOwner {
        swapStorage.setAdminFee(newAdminFee);
    }
    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapStorage.setSwapFee(newSwapFee);
    }
    function setDefaultWithdrawFee(uint256 newWithdrawFee) external onlyOwner {
        swapStorage.setDefaultWithdrawFee(newWithdrawFee);
    }
    function rampA(uint256 futureA, uint256 futureTime) external onlyOwner {
        swapStorage.rampA(futureA, futureTime);
    }
    function stopRampA() external onlyOwner {
        swapStorage.stopRampA();
    }
    function setIsGuarded(bool isGuarded_) external onlyOwner {
        isGuarded = isGuarded_;
    }
}