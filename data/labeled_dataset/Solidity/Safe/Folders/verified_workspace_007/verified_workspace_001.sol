import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
pragma solidity 0.8.10;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract WorthToken is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    string private constant NAME = "Worthpad";
    string private constant SYMBOL = "WORTH";
    uint8 private constant DECIMALS = 18;
    uint256 private constant FEES_DIVISOR = 10**3;
    uint256 private constant TOTAL_SUPPLY = 100 * 10**9 * 10**DECIMALS;
    uint256 public _liquidityFee = 25;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _worthDVCFundFee = 25;
    address public worthDVCFundWallet;
    uint256 private _previousWorthDVCFundFee = _worthDVCFundFee;
    uint256 private withdrawableBalance;
    uint256 public _maxTxAmount = 10 * 10**6 * 10**DECIMALS;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 private numTokensSellToAddToLiquidity = 1 * 10**6 * 10**DECIMALS;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event ExcludeFromFeeEvent(bool value);
    event IncludeInFeeEvent(bool value);
    event SetWorthDVCFundWalletEvent(address value);
    event SetLiquidityFeePercentEvent(uint256 value);
    event SetWorthDVCFundFeePercentEvent(uint256 value);
    event SetMinSellEvent(uint256 value);
    event SetMaxTxAmountEvent(uint256 value);
    event SetRouterAddressEvent(address value);
    event BNBWithdrawn(address beneficiary,uint256 value);
    constructor (address _worthDVCFundWallet) {
        require(_worthDVCFundWallet != address(0),"Should not be address 0");
        _balances[_msgSender()] = TOTAL_SUPPLY;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        worthDVCFundWallet = _worthDVCFundWallet;
        emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    }
    function name() public pure returns (string memory) {
        return NAME;
    }
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }
    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function getMinAutoLiquidityAmount() public view returns (uint256) {
        return numTokensSellToAddToLiquidity;
    }
    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    receive() external payable {}
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        _tokenTransfer(from,to,amount);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        withdrawableBalance = address(this).balance;
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > FEES_DIVISOR.div(_worthDVCFundFee), "Transaction amount is too small");
        require(amount > FEES_DIVISOR.div(_liquidityFee), "Transaction amount is too small");
        uint256 worthDVCFundFee = 0;
        uint256 liquidityAmount = 0;
        if (_isExcludedFromFee[sender]) {
            _transferStandard(sender, recipient, amount);
        } else {
            if(_worthDVCFundFee > 0) {
                worthDVCFundFee = amount.mul(_worthDVCFundFee).div(FEES_DIVISOR);
            }
            if(_liquidityFee > 0) {
                liquidityAmount = amount.mul(_liquidityFee).div(FEES_DIVISOR);
            }
            _transferStandard(sender, recipient, (amount.sub(worthDVCFundFee).sub(liquidityAmount)));
            _transferStandard(sender, worthDVCFundWallet, worthDVCFundFee);
            _transferStandard(sender, address(this), liquidityAmount);
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }
    function excludeFromFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] == false, "Address is already excluded from Fee");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFeeEvent(true);
    }
    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] == true, "Address is already included in Fee");
        _isExcludedFromFee[account] = false;
        emit IncludeInFeeEvent(true);
    }
    function disableAllFees() external onlyOwner {
        delete _liquidityFee;
        _previousLiquidityFee = _liquidityFee;
        delete _worthDVCFundFee;
        _previousWorthDVCFundFee = _worthDVCFundFee;
        swapAndLiquifyEnabled = false;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }
    function enableAllFees() external onlyOwner {
        _liquidityFee = 25;
        _previousLiquidityFee = _liquidityFee;
        _worthDVCFundFee = 25;
        _previousWorthDVCFundFee = _worthDVCFundFee;
        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }
    function setWorthDVCFundWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0),"Should not be address 0");
        require(newWallet != worthDVCFundWallet,"Should be a new Address");
        worthDVCFundWallet = newWallet;
        emit SetWorthDVCFundWalletEvent(newWallet);
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(liquidityFee >= 10 && liquidityFee <= 100, "Liquidity Fee can never be set below 1% or exceed 10%");
        _liquidityFee = liquidityFee;
        emit SetLiquidityFeePercentEvent(liquidityFee);
    }
    function setWorthDVCFundFeePercent(uint256 worthDVCFundFee) external onlyOwner {
        require(worthDVCFundFee >= 10 && worthDVCFundFee <= 100, "Worth DVC Fund Fee can never be set below 1% or exceed 10%");
        _worthDVCFundFee = worthDVCFundFee;
        emit SetWorthDVCFundFeePercentEvent(worthDVCFundFee);
    }
    function setMinSell(uint256 amount) external onlyOwner {
        require(amount > 0 && amount < _maxTxAmount, "Minimum Sell Amount should be greater than 0 and less than max transaction amount");
        numTokensSellToAddToLiquidity = amount * 10**DECIMALS;
        emit SetMinSellEvent(amount);
    }
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount > 0 && maxTxAmount < 100000000, "Max Transaction Amount should be greater than 0 and less than 0.1% of the total supply");
        _maxTxAmount = maxTxAmount * 10**DECIMALS;
        emit SetMaxTxAmountEvent(maxTxAmount);
    }
    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(0),"Should not be address 0");
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
        emit SetRouterAddressEvent(newRouter);
    }
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }
    function withdrawLockedBNB(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        require(withdrawableBalance > 0, "The BNB balance must be greater than 0");
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Transfer failed.");
        emit BNBWithdrawn(recipient, amount);
    }
}